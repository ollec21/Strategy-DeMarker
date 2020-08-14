/**
 * @file
 * Implements DeMarker strategy based on for the DeMarker indicator.
 */

// User input params.
INPUT int DeMarker_Period = 12;                 // Period
INPUT int DeMarker_Shift = 1;                   // Shift
INPUT int DeMarker_SignalOpenMethod = 12;       // Signal open method (-31-31)
INPUT float DeMarker_SignalOpenLevel = 0.5;     // Signal open level (0.0-0.5)
INPUT int DeMarker_SignalOpenFilterMethod = 0;  // Signal open filter method
INPUT int DeMarker_SignalOpenBoostMethod = 0;   // Signal open boost method
INPUT int DeMarker_SignalCloseMethod = 0;       // Signal close method (-63-63)
INPUT float DeMarker_SignalCloseLevel = 0.5;    // Signal close level (0.0-0.5)
INPUT int DeMarker_PriceLimitMethod = 0;        // Price limit method
INPUT float DeMarker_PriceLimitLevel = 0;       // Price limit level
INPUT float DeMarker_MaxSpread = 6.0;           // Max spread to trade (pips)

// Includes.
#include <EA31337-classes/Indicators/Indi_DeMarker.mqh>
#include <EA31337-classes/Strategy.mqh>

// Struct to define strategy parameters to override.
struct Stg_DeMarker_Params : StgParams {
  unsigned int DeMarker_Period;
  int DeMarker_Shift;
  int DeMarker_SignalOpenMethod;
  float DeMarker_SignalOpenLevel;
  int DeMarker_SignalOpenFilterMethod;
  int DeMarker_SignalOpenBoostMethod;
  int DeMarker_SignalCloseMethod;
  float DeMarker_SignalCloseLevel;
  int DeMarker_PriceLimitMethod;
  float DeMarker_PriceLimitLevel;
  float DeMarker_MaxSpread;

  // Constructor: Set default param values.
  Stg_DeMarker_Params()
      : DeMarker_Period(::DeMarker_Period),
        DeMarker_Shift(::DeMarker_Shift),
        DeMarker_SignalOpenMethod(::DeMarker_SignalOpenMethod),
        DeMarker_SignalOpenLevel(::DeMarker_SignalOpenLevel),
        DeMarker_SignalOpenFilterMethod(::DeMarker_SignalOpenFilterMethod),
        DeMarker_SignalOpenBoostMethod(::DeMarker_SignalOpenBoostMethod),
        DeMarker_SignalCloseMethod(::DeMarker_SignalCloseMethod),
        DeMarker_SignalCloseLevel(::DeMarker_SignalCloseLevel),
        DeMarker_PriceLimitMethod(::DeMarker_PriceLimitMethod),
        DeMarker_PriceLimitLevel(::DeMarker_PriceLimitLevel),
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
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Stg_DeMarker_Params>(_params, _tf, stg_dm_m1, stg_dm_m5, stg_dm_m15, stg_dm_m30, stg_dm_h1,
                                         stg_dm_h4, stg_dm_h4);
    }
    // Initialize strategy parameters.
    DeMarkerParams dm_params(_params.DeMarker_Period);
    dm_params.SetTf(_tf);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_DeMarker(dm_params), NULL, NULL);
    sparams.logger.Ptr().SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.DeMarker_SignalOpenMethod, _params.DeMarker_SignalOpenLevel,
                       _params.DeMarker_SignalOpenFilterMethod, _params.DeMarker_SignalOpenBoostMethod,
                       _params.DeMarker_SignalCloseMethod, _params.DeMarker_SignalCloseMethod);
    sparams.SetPriceLimits(_params.DeMarker_PriceLimitMethod, _params.DeMarker_PriceLimitLevel);
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
   *   _method (int) - signal method to use by using bitwise AND operation
   *   _level (double) - signal level to consider the signal
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0) {
    Chart *_chart = Chart();
    Indi_DeMarker *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    if (!_result) {
      // Returns false when indicator data is not valid.
      _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
      return false;
    }
    double level = _level * Chart().GetPipSize();
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result = _indi[CURR].value[0] < 0.5 - _level;
        if (_method != 0) {
          if (METHOD(_method, 0)) _result &= _indi[PREV].value[0] < 0.5 - _level;
          if (METHOD(_method, 1)) _result &= _indi[PPREV].value[0] < 0.5 - _level;          // @to-remove?
          if (METHOD(_method, 2)) _result &= _indi[CURR].value[0] < _indi[PREV].value[0];   // @to-remove?
          if (METHOD(_method, 3)) _result &= _indi[PREV].value[0] < _indi[PPREV].value[0];  // @to-remove?
          if (METHOD(_method, 4)) _result &= _indi[PREV].value[0] < 0.5 - _level - _level / 2;
        }
        break;
      case ORDER_TYPE_SELL:
        _result = _indi[CURR].value[0] > 0.5 + _level;
        if (_method != 0) {
          if (METHOD(_method, 0)) _result &= _indi[PREV].value[0] > 0.5 + _level;
          if (METHOD(_method, 1)) _result &= _indi[PPREV].value[0] > 0.5 + _level;
          if (METHOD(_method, 2)) _result &= _indi[CURR].value[0] > _indi[PREV].value[0];
          if (METHOD(_method, 3)) _result &= _indi[PREV].value[0] > _indi[PPREV].value[0];
          if (METHOD(_method, 4)) _result &= _indi[PREV].value[0] > 0.5 + _level + _level / 2;
        }
        break;
    }
    return _result;
  }

  /**
   * Gets price limit value for profit take or stop loss.
   */
  float PriceLimit(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_DeMarker *_indi = Data();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    switch (_method) {
      case 0: {
        int _bar_count = (int)_level * (int)_indi.GetPeriod();
        _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count))
                                 : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
        break;
      }
      case 1: {
        int _bar_count = (int)_level * (int)_indi.GetPeriod();
        _result = _direction < 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count))
                                 : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
        break;
      }
    }
    return (float)_result;
  }
};
