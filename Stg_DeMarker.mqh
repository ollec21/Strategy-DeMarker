//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/**
 * @file
 * Implements DeMarker strategy based on for the DeMarker indicator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_DeMarker.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT string __DeMarker_Parameters__ = "-- DeMarker strategy params --";  // >>> DEMARKER <<<
INPUT int DeMarker_Active_Tf = 0;             // Activate timeframes (1-255, e.g. M1=1,M5=2,M15=4,M30=8,H1=16,H2=32...)
INPUT int DeMarker_Period = 68;               // Period
INPUT int DeMarker_Shift = 1;                 // Shift
INPUT double DeMarker_SignalOpenLevel = 0.5;  // Signal open level (0.0-0.5)
INPUT ENUM_TRAIL_TYPE DeMarker_TrailingStopMethod = 23;    // Trail stop method
INPUT ENUM_TRAIL_TYPE DeMarker_TrailingProfitMethod = 22;  // Trail profit method
INPUT int DeMarker1_SignalBaseMethod = 12;                 // Signal base method (-31-31)
INPUT int DeMarker1_OpenCondition1 = 680;                  // Open condition 1 (0-1023)
INPUT int DeMarker1_OpenCondition2 = 0;                    // Open condition 2 (0-1023)
INPUT ENUM_MARKET_EVENT DeMarker1_CloseCondition = 1;      // Close condition for M1
INPUT double DeMarker_MaxSpread = 6.0;                     // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_DeMarker_Params : Stg_Params {
  unsigned int DeMarker_Period;
  ENUM_APPLIED_PRICE DeMarker_Applied_Price;
  int DeMarker_Shift;
  ENUM_TRAIL_TYPE DeMarker_TrailingStopMethod;
  ENUM_TRAIL_TYPE DeMarker_TrailingProfitMethod;
  double DeMarker_SignalOpenLevel;
  long DeMarker_SignalBaseMethod;
  long DeMarker_SignalOpenMethod1;
  long DeMarker_SignalOpenMethod2;
  double DeMarker_SignalCloseLevel;
  ENUM_MARKET_EVENT DeMarker_SignalCloseMethod1;
  ENUM_MARKET_EVENT DeMarker_SignalCloseMethod2;
  double DeMarker_MaxSpread;

  // Constructor: Set default param values.
  Stg_DeMarker_Params()
      : DeMarker_Period(::DeMarker_Period),
        DeMarker_Applied_Price(::DeMarker_Applied_Price),
        DeMarker_Shift(::DeMarker_Shift),
        DeMarker_TrailingStopMethod(::DeMarker_TrailingStopMethod),
        DeMarker_TrailingProfitMethod(::DeMarker_TrailingProfitMethod),
        DeMarker_SignalOpenLevel(::DeMarker_SignalOpenLevel),
        DeMarker_SignalBaseMethod(::DeMarker_SignalBaseMethod),
        DeMarker_SignalOpenMethod1(::DeMarker_SignalOpenMethod1),
        DeMarker_SignalOpenMethod2(::DeMarker_SignalOpenMethod2),
        DeMarker_SignalCloseLevel(::DeMarker_SignalCloseLevel),
        DeMarker_SignalCloseMethod1(::DeMarker_SignalCloseMethod1),
        DeMarker_SignalCloseMethod2(::DeMarker_SignalCloseMethod2),
        DeMarker_MaxSpread(::DeMarker_MaxSpread) {}
};

// Loads pair specific param values.
#include "sets/EURUSD_H1.h"
#include "sets/EURUSD_H4.h"
#include "sets/EURUSD_M1.h"
#include "sets/EURUSD_M15.h"
#include "sets/EURUSD_M30.h"
#include "sets/EURUSD_M5.h"

class Stg_DeMarker : public Strategy {
 public:
  Stg_DeMarker(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_DeMarker *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Stg_DeMarker_Params _params;
    switch (_tf) {
      case PERIOD_M1: {
        Stg_DeMarker_EURUSD_M1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M5: {
        Stg_DeMarker_EURUSD_M5_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M15: {
        Stg_DeMarker_EURUSD_M15_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M30: {
        Stg_DeMarker_EURUSD_M30_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H1: {
        Stg_DeMarker_EURUSD_H1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H4: {
        Stg_DeMarker_EURUSD_H4_Params _new_params;
        _params = _new_params;
      }
    }
    // Initialize strategy parameters.
    ChartParams cparams(_tf);
    DeMarker_Params adx_params(_params.DeMarker_Period, _params.DeMarker_Applied_Price);
    IndicatorParams adx_iparams(10, INDI_DeMarker);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_DeMarker(adx_params, adx_iparams, cparams), NULL, NULL);
    sparams.logger.SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.DeMarker_SignalBaseMethod, _params.DeMarker_SignalOpenMethod1,
                       _params.DeMarker_SignalOpenMethod2, _params.DeMarker_SignalCloseMethod1,
                       _params.DeMarker_SignalCloseMethod2, _params.DeMarker_SignalOpenLevel,
                       _params.DeMarker_SignalCloseLevel);
    sparams.SetStops(_params.DeMarker_TrailingProfitMethod, _params.DeMarker_TrailingStopMethod);
    sparams.SetMaxSpread(_params.DeMarker_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_DeMarker(sparams, "DeMarker");
    return _strat;
  }

  /**
   * Check if DeMarker indicator is on buy or sell.
   * Demarker Technical Indicator is based on the comparison of the period maximum with the previous period maximum.
   *
   * @param
   *   _cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   _signal_method (int) - signal method to use by using bitwise AND operation
   *   _signal_level1 (double) - signal level to consider the signal
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    bool _result = false;
    double demarker_0 = ((Indi_DeMarker *)this.Data()).GetValue(0);
    double demarker_1 = ((Indi_DeMarker *)this.Data()).GetValue(1);
    double demarker_2 = ((Indi_DeMarker *)this.Data()).GetValue(2);
    if (_signal_method == EMPTY) _signal_method = GetSignalBaseMethod();
    if (_signal_level1 == EMPTY) _signal_level1 = GetSignalLevel1();
    if (_signal_level2 == EMPTY) _signal_level2 = GetSignalLevel2();
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result = demarker_0 < 0.5 - _signal_level1;
        if (_signal_method != 0) {
          if (METHOD(_signal_method, 0)) _result &= demarker_1 < 0.5 - _signal_level1;
          if (METHOD(_signal_method, 1)) _result &= demarker_2 < 0.5 - _signal_level1;  // @to-remove?
          if (METHOD(_signal_method, 2)) _result &= demarker_0 < demarker_1;            // @to-remove?
          if (METHOD(_signal_method, 3)) _result &= demarker_1 < demarker_2;            // @to-remove?
          if (METHOD(_signal_method, 4)) _result &= demarker_1 < 0.5 - _signal_level1 - _signal_level1 / 2;
        }
        // PrintFormat("DeMarker buy: %g <= %g", demarker_0, 0.5 - _signal_level1);
        break;
      case ORDER_TYPE_SELL:
        _result = demarker_0 > 0.5 + _signal_level1;
        if (_signal_method != 0) {
          if (METHOD(_signal_method, 0)) _result &= demarker_1 > 0.5 + _signal_level1;
          if (METHOD(_signal_method, 1)) _result &= demarker_2 > 0.5 + _signal_level1;
          if (METHOD(_signal_method, 2)) _result &= demarker_0 > demarker_1;
          if (METHOD(_signal_method, 3)) _result &= demarker_1 > demarker_2;
          if (METHOD(_signal_method, 4)) _result &= demarker_1 > 0.5 + _signal_level1 + _signal_level1 / 2;
        }
        // PrintFormat("DeMarker sell: %g >= %g", demarker_0, 0.5 + _signal_level1);
        break;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    if (_signal_level == EMPTY) _signal_level = GetSignalCloseLevel();
    return SignalOpen(Order::NegateOrderType(_cmd), _signal_method, _signal_level);
  }
};
