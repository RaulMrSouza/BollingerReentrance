//+------------------------------------------------------------------+ 
//|                                          BollingerReentrance.mq5 | 
//|                          Altered version of Demo_iBands.mq5 from |
//|                  https://www.mql5.com/en/docs/indicators/ibands  |
//|         this one display arrows for possible buy and sell trades |                    
//|                                             https://www.mql5.com | 
//+------------------------------------------------------------------+ 

//+------------------------------------------------------------------+ 
//|                                                  Demo_iBands.mq5 | 
//|                        Copyright 2011, MetaQuotes Software Corp. | 
//|                                             https://www.mql5.com | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright 2011, MetaQuotes Software Corp." 
#property link      "https://www.mql5.com" 
#property version   "1.00" 
#property description "The indicator demonstrates how to obtain data" 
#property description "of indicator buffers for the iBands technical indicator." 
#property description "A symbol and timeframe used for calculation of the indicator," 
#property description "are set by the symbol and period parameters." 
#property description "The method of creation of the handle is set through the 'type' parameter (function type)." 

#property indicator_chart_window 
#property indicator_buffers 7 
#property indicator_plots   7 
//--- the Upper plot 
#property indicator_label1  "Upper" 
#property indicator_type1   DRAW_LINE 
#property indicator_color1  clrMediumSeaGreen 
#property indicator_style1  STYLE_SOLID 
#property indicator_width1  1 
//--- the Lower plot 
#property indicator_label2  "Lower" 
#property indicator_type2   DRAW_LINE 
#property indicator_color2  clrMediumSeaGreen 
#property indicator_style2  STYLE_SOLID 
#property indicator_width2  1 
//--- the Middle plot 
#property indicator_label3  "Middle" 
#property indicator_type3   DRAW_LINE 
#property indicator_color3  clrMediumSeaGreen 
#property indicator_style3  STYLE_SOLID 
#property indicator_width3  1 


#property indicator_color4  Blue
#property indicator_type4   DRAW_ARROW
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2
#property indicator_color5  Red
#property indicator_type5   DRAW_ARROW
#property indicator_style5  STYLE_SOLID
#property indicator_width5  2

#property indicator_color6  Purple
#property indicator_type6   DRAW_ARROW
#property indicator_style6  STYLE_SOLID
#property indicator_width6  2
#property indicator_color7  Orange
#property indicator_type7   DRAW_ARROW
#property indicator_style7  STYLE_SOLID
#property indicator_width7  2

double BufferBBBuy[];
double BufferBBSell[];
double BufferSBBuy[];
double BufferSBSell[];
//+------------------------------------------------------------------+ 
//| Enumeration of the methods of handle creation                    | 
//+------------------------------------------------------------------+ 
enum Creation
  {
   Call_iBands,            // use iBands 
   Call_IndicatorCreate    // use IndicatorCreate 
  };
//--- input parameters 
input Creation             type=Call_iBands;          // type of the function  
input int                  bands_period=20;           // period of moving average 
input int                  bands_shift=0;             // shift 
input double               deviation=2.0;             // number of standard deviations  
input ENUM_APPLIED_PRICE   applied_price=PRICE_CLOSE; // type of price 
input string               symbol=" ";                // symbol  
input ENUM_TIMEFRAMES      period=PERIOD_CURRENT;     // timeframe 
input bool      higher_volume=false;     // Volume higher than last candle
input bool      single_bar=true;     // Show Single Bar Arrow
input bool      display_Alert=true;     // Alert messages for arrows
//--- indicator buffers 
double         UpperBuffer[];
double         LowerBuffer[];
double         MiddleBuffer[];
//--- variable for storing the handle of the iBands indicator 
int    handle;
//--- variable for storing 
string name=symbol;
//--- name of the indicator on a chart 
string short_name;
//--- we will keep the number of values in the Bollinger Bands indicator 
int    bars_calculated=0;

bool show_alert;
string alert_msg;
datetime date_alert;
//+------------------------------------------------------------------+ 
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+ 
int OnInit()
  {
//--- assignment of arrays to indicator buffers 
   SetIndexBuffer(0,UpperBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,LowerBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,MiddleBuffer,INDICATOR_DATA);
//--- set shift of each line 
   PlotIndexSetInteger(0,PLOT_SHIFT,bands_shift);
   PlotIndexSetInteger(1,PLOT_SHIFT,bands_shift);
   PlotIndexSetInteger(2,PLOT_SHIFT,bands_shift);
//--- determine the symbol the indicator is drawn for 
   name=symbol;
//--- delete spaces to the right and to the left 
   StringTrimRight(name);
   StringTrimLeft(name);
//--- if it results in zero length of the 'name' string 
   if(StringLen(name)==0)
     {
      //--- take the symbol of the chart the indicator is attached to 
      name=_Symbol;
     }
//--- create handle of the indicator 
   if(type==Call_iBands)
      handle=iBands(name,period,bands_period,bands_shift,deviation,applied_price);
   else
     {
      //--- fill the structure with parameters of the indicator 
      MqlParam pars[4];
      //--- period of ma 
      pars[0].type=TYPE_INT;
      pars[0].integer_value=bands_period;
      //--- shift 
      pars[1].type=TYPE_INT;
      pars[1].integer_value=bands_shift;
      //--- number of standard deviation 
      pars[2].type=TYPE_DOUBLE;
      pars[2].double_value=deviation;
      //--- type of price 
      pars[3].type=TYPE_INT;
      pars[3].integer_value=applied_price;
      handle=IndicatorCreate(name,period,IND_BANDS,4,pars);
     }
//--- if the handle is not created 
   if(handle==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iBands indicator for the symbol %s/%s, error code %d",
                  name,
                  EnumToString(period),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- show the symbol/timeframe the Bollinger Bands indicator is calculated for 
   short_name=StringFormat("iBands(%s/%s, %d,%d,%G,%s)",name,EnumToString(period),
                           bands_period,bands_shift,deviation,EnumToString(applied_price));
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);

//---- indicator buffers mapping  
   SetIndexBuffer(3,BufferBBBuy,INDICATOR_DATA);
   SetIndexBuffer(4,BufferBBSell,INDICATOR_DATA);
   SetIndexBuffer(5,BufferSBBuy,INDICATOR_DATA);
   SetIndexBuffer(6,BufferSBSell,INDICATOR_DATA);

//---- drawing settings
   PlotIndexSetInteger(3,PLOT_ARROW,233);
   PlotIndexSetInteger(4,PLOT_ARROW,234);

   PlotIndexSetInteger(5,PLOT_ARROW,233);
   PlotIndexSetInteger(6,PLOT_ARROW,234);

   PlotIndexSetString(3,PLOT_LABEL,"BB Buy");
   PlotIndexSetString(4,PLOT_LABEL,"BB Sell");

   PlotIndexSetString(5,PLOT_LABEL,"Single Bar Buy");
   PlotIndexSetString(6,PLOT_LABEL,"Single Bar Sell");

//--- normal initialization of the indicator   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+ 
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+ 
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- number of values copied from the iBands indicator 
   int values_to_copy;
//--- determine the number of values calculated in the indicator 
   int calculated=BarsCalculated(handle);
   if(calculated<=0)
     {
      PrintFormat("BarsCalculated() returned %d, error code %d",calculated,GetLastError());
      return(0);
     }
//--- if it is the first start of calculation of the indicator or if the number of values in the iBands indicator changed 
//---or if it is necessary to calculated the indicator for two or more bars (it means something has changed in the price history) 
   if(prev_calculated==0 || calculated!=bars_calculated || rates_total>prev_calculated+1)
     {
      //--- if the size of indicator buffers is greater than the number of values in the iBands indicator for symbol/period, then we don't copy everything  
      //--- otherwise, we copy less than the size of indicator buffers 
      if(calculated>rates_total) values_to_copy=rates_total;
      else                       values_to_copy=calculated;
     }
   else
     {
      //--- it means that it's not the first time of the indicator calculation, and since the last call of OnCalculate() 
      //--- for calculation not more than one bar is added 
      values_to_copy=(rates_total-prev_calculated)+1;
     }
//--- fill the array with values of the Bollinger Bands indicator 
//--- if FillArraysFromBuffer returns false, it means the information is nor ready yet, quit operation 
   if(!FillArraysFromBuffers(MiddleBuffer,UpperBuffer,LowerBuffer,bands_shift,handle,values_to_copy)) return(0);
//--- form the message 

   int start;
   double Buffer[];

   if(prev_calculated==0) start=1;
   else start=prev_calculated-1;    // set start equal to the last index in the arrays 

   if(prev_calculated==0)
     {
      BufferBBBuy[0]=0;
      BufferBBSell[0]=0;
      BufferSBBuy[0] = 0;
      BufferSBSell[0]= 0;
     }

   for(int i=start;i<rates_total;i++)
     {
      BufferBBBuy[i]=0;
      BufferBBSell[i]=0;
      BufferSBBuy[i] = 0;
      BufferSBSell[i]= 0;

      if(!higher_volume || volume[i]>volume[i-1])
        {
         if(close[i-1]<=LowerBuffer[i-1] && close[i]>=LowerBuffer[i])
           {
            BufferBBBuy[i]=low[i]-(high[i]-low[i])/2;
           }
         else if(close[i-1]>=UpperBuffer[i-1] && close[i]<=UpperBuffer[i])
           {
            BufferBBSell[i]=high[i]+(high[i]-low[i])/2;
           }
        }

      if(single_bar && i>=4)
        {
         bool bullish=false;
         bool sequence=true;

         if(close[i]!=open[i] && (!higher_volume || volume[i]<volume[i-1]))
           {
            if(close[i]>open[i])
               bullish=true;

            for(int j=1;j<=3;j++)
              {
               if(bullish)
                 {
                  if(close[i-j]>=open[i-j])
                    {
                     sequence=false;
                     break;
                    }
                 }
               else
                 {
                  if(close[i-j]<=open[i-j])
                    {
                     sequence=false;
                     break;
                    }
                 }
              }
            if(sequence)
              {
               if(bullish)
                  BufferSBSell[i]=high[i]+(high[i]-low[i])/2;
               else
                  BufferSBBuy[i]=low[i]-(high[i]+low[i])/2;
              }
           }
        }

      if(i == rates_total-1  && display_Alert && (BufferBBBuy[i-1]!=0 || BufferBBSell[i-1]!=0 || BufferSBBuy[i-1]!=0 || BufferSBSell[i-1]!=0))
        {
         if(BufferBBBuy[i-1]!=0)
            alert_msg="BB Buy "+(high[i-1]+15);
         if(BufferBBSell[i-1]!=0)
            alert_msg="BB Sell "+(low[i-1]-15);
         if(BufferSBBuy[i-1]!=0)
            alert_msg="Single Bar Buy "+(high[i-1]+15);
         if(BufferSBSell[i-1]!=0)
            alert_msg="Single Bar Sell "+(low[i-1]-15);

         if(date_alert!=time[i-1])
           {
            Alert(Symbol()," ",period," ",alert_msg);
            date_alert=time[i-1];
           }
        }
     }


//--- memorize the number of values in the Bollinger Bands indicator 
   bars_calculated=calculated;
//--- return the prev_calculated value for the next call 
   return(rates_total);
  }
//+------------------------------------------------------------------+ 
//| Filling indicator buffers from the iBands indicator              | 
//+------------------------------------------------------------------+ 
bool FillArraysFromBuffers(double &base_values[],     // indicator buffer of the middle line of Bollinger Bands 
                           double &upper_values[],    // indicator buffer of the upper border 
                           double &lower_values[],    // indicator buffer of the lower border 
                           int shift,                 // shift 
                           int ind_handle,            // handle of the iBands indicator 
                           int amount                 // number of copied values 
                           )
  {
//--- reset error code 
   ResetLastError();
//--- fill a part of the MiddleBuffer array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(ind_handle,0,-shift,amount,base_values)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iBands indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(false);
     }

//--- fill a part of the UpperBuffer array with values from the indicator buffer that has index 1 
   if(CopyBuffer(ind_handle,1,-shift,amount,upper_values)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iBands indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(false);
     }

//--- fill a part of the LowerBuffer array with values from the indicator buffer that has index 2 
   if(CopyBuffer(ind_handle,2,-shift,amount,lower_values)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iBands indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(false);
     }
//--- everything is fine 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Indicator deinitialization function                              | 
//+------------------------------------------------------------------+ 
void OnDeinit(const int reason)
  {
//--- clear the chart after deleting the indicator 
   Comment("");
  }
//+------------------------------------------------------------------+
