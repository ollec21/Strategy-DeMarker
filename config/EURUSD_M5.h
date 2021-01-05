/**
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_DeMarker_Params_M5 : Indi_DeMarker_Params {
  Indi_DeMarker_Params_M5() : Indi_DeMarker_Params(indi_demarker_defaults, PERIOD_M5) {
    period = 8;
    shift = 0;
  }
} indi_demarker_m5;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_DeMarker_Params_M5 : StgParams {
  // Struct constructor.
  Stg_DeMarker_Params_M5() : StgParams(stg_demarker_defaults) {
    lot_size = 0;
    signal_open_method = -4;
    signal_open_filter = 14;
    signal_open_level = (float)0.0;
    signal_open_boost = 1;
    signal_close_method = 0;
    signal_close_level = (float)0.0;
    price_stop_method = 0;
    price_stop_level = 0.0;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_demarker_m5;
