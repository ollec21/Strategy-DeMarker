//+------------------------------------------------------------------+
//|                 EA31337 - multi-strategy advanced trading robot. |
//|                       Copyright 2016-2017, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
    This file is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Properties.
#property strict

/**
 * @file
 * Implementation of DeMarker Strategy based on the DeMarker indicator.
 *
 * @docs
 * - https://docs.mql4.com/indicators/iDeMarker
 * - https://www.mql5.com/en/docs/indicators/iDeMarker
 */

// Includes.
#include <EA31337-classes\Strategy.mqh>
#include <EA31337-classes\Strategies.mqh>

// User inputs.
#ifdef __input__ input #endif string __DeMarker_Parameters__ = "-- Settings for the DeMarker indicator --"; // >>> DEMARKER <<<
#ifdef __input__ input #endif int DeMarker_Period = 17; // Period
#ifdef __input__ input #endif double DeMarker_Period_Ratio = 0.3; // Period ratio between timeframes (0.5-1.5)
#ifdef __input__ input #endif int DeMarker_Shift = 0; // Shift
#ifdef __input__ input #endif double DeMarker_SignalLevel = -0.30000000; // Signal level (0.0-0.4)
#ifdef __input__ input #endif int DeMarker_SignalMethod = 12; // Signal method for M1 (-31-31)

class DeMarker: public Strategy {
protected:

  double demarker[H1][FINAL_ENUM_INDICATOR_INDEX];
  int       open_method = EMPTY;    // Open method.
  double    open_level  = 0.0;     // Open level.

    public:

  /**
   * Update indicator values.
   */
  bool Update(int tf = EMPTY) {
    // Calculates the DeMarker indicator.
    ratio = tf == 30 ? 1.0 : fmax(DeMarker_Period_Ratio, NEAR_ZERO) / tf * 30;
    for (i = 0; i < FINAL_ENUM_INDICATOR_INDEX; i++) {
      demarker[index][i] = iDeMarker(symbol, tf, (int) (DeMarker_Period * ratio), i + DeMarker_Shift);
    }
    // success = (bool) demarker[index][CURR] + demarker[index][PREV] + demarker[index][FAR];
    // PrintFormat("Period: %d, DeMarker: %g", period, demarker[index][CURR]);
    if (VerboseDebug) PrintFormat("DeMarker M%d: %s", tf, Arrays::ArrToString2D(demarker, ",", Digits));
  }

  /**
   * Checks whether signal is on buy or sell.
   * Demarker Technical Indicator is based on the comparison of the period maximum with the previous period maximum.
   *
   * @param
   *   cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   signal_method (int) - signal method to use by using bitwise AND operation
   *   signal_level (double) - signal level to consider the signal
   */
  bool Signal(int cmd, ENUM_TIMEFRAMES tf = PERIOD_M1, int signal_method = EMPTY, double signal_level = EMPTY) {
    bool result = FALSE; int period = Timeframe::TfToIndex(tf);
    UpdateIndicator(S_DEMARKER, tf);
    if (signal_method == EMPTY) signal_method = GetStrategySignalMethod(S_DEMARKER, tf, 0);
    if (signal_level == EMPTY)  signal_level  = GetStrategySignalLevel(S_DEMARKER, tf, 0.0);
    switch (cmd) {
      case OP_BUY:
        result = demarker[period][CURR] < 0.5 - signal_level;
        if ((signal_method &   1) != 0) result &= demarker[period][PREV] < 0.5 - signal_level;
        if ((signal_method &   2) != 0) result &= demarker[period][FAR] < 0.5 - signal_level;
        if ((signal_method &   4) != 0) result &= demarker[period][CURR] < demarker[period][PREV];
        if ((signal_method &   8) != 0) result &= demarker[period][PREV] < demarker[period][FAR];
        if ((signal_method &  16) != 0) result &= demarker[period][PREV] < 0.5 - signal_level - signal_level/2;
        // PrintFormat("DeMarker buy: %g <= %g", demarker[period][CURR], 0.5 - signal_level);
        break;
      case OP_SELL:
        result = demarker[period][CURR] > 0.5 + signal_level;
        if ((signal_method &   1) != 0) result &= demarker[period][PREV] > 0.5 + signal_level;
        if ((signal_method &   2) != 0) result &= demarker[period][FAR] > 0.5 + signal_level;
        if ((signal_method &   4) != 0) result &= demarker[period][CURR] > demarker[period][PREV];
        if ((signal_method &   8) != 0) result &= demarker[period][PREV] > demarker[period][FAR];
        if ((signal_method &  16) != 0) result &= demarker[period][PREV] > 0.5 + signal_level + signal_level/2;
        // PrintFormat("DeMarker sell: %g >= %g", demarker[period][CURR], 0.5 + signal_level);
        break;
    }
    result &= signal_method <= 0 || Convert::ValueToOp(curr_trend) == cmd;
    if (VerboseTrace && result) {
      PrintFormat("%s:%d: Signal: %d/%d/%d/%g", __FUNCTION__, __LINE__, cmd, tf, signal_method, signal_level);
    }
    return result;
  }
};
