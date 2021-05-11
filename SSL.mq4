//+------------------------------------------------------------------+
//|                                                       SSL-v2.mq4 |
//|                                                   Andreas Mendes |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Andreas Mendes"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <CustomFunctions01.mqh>
const string  IndicatorName = "ssl-channel-chart-alert-indicator";
const string Indicator1 = "chaikin-money-flow-indicator";
const string BaseLine = "cQ-Baseline_v1.6";

const string volume = "damiani_volatmeter";
string absoluteStrength = "absolute-strength-histogram";
bool longContinuationEntry;
bool shortContinuationEntry;
const int BufferBear = 0;
const int BufferBull = 1;
//Example 1
enum BaselineTypes{
   LWMA = 1,
   SMA = 2,
   EMA = 3,
   AMA = 4,
   ALMA = 5,
   DEMA = 6,
   FRAMA = 7,
   HALF_TREND = 8,
   HULL = 9,
   JURIK = 10,
   KAMA = 11,
   KIJUN_SEN = 12,
   LAGUERRE = 13,
   MCGINLEY = 14,
   TEMA = 15,
   TMA1 = 16,
   TMA2 = 17,
   TREND_MAGIC = 18,
   VIDYA = 19,

   
};
  


//input const string BaselineType[2] = {'a','b'};
int order_Type;
int refresherCQ = 20;
int differenceInPips;
input BaselineTypes selectBaselineType = LWMA;
input int Baseline_Period = 20;
input int cmfPeriod = 20;   
input double maxRiskPrc = 0.02;
input bool highRiskMode = false; 
input int SSL_Period = 10;
input int ABS_MODE= 0;
input int length = 9;
input int smooth = 1;
input int signal = 4;
input int ATR_Days =14;
input int viscosity = 7;
input int sedimentation  = 50;
input double thresHold_lvl = 1.1;

input int magicNum = 1994;
int orderID;
int orderID_2;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Alert("The EA has started");
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+

int CheckBaseLineCross(double baseline,double openPrice ,double closePrice)
{
      static int previous_direction = 0;
      static int current_direction = 0;
      
      //Up Direction =1
      if(openPrice < baseline && closePrice > baseline)
      {
            current_direction = 1;
      }
      
      if(openPrice> baseline && closePrice<baseline)
      {
        current_direction = 2;
      }
        //Detect a direction change 
     if(current_direction != previous_direction){
        previous_direction = current_direction;
        return (previous_direction);
     } else {
        return (0);
     }
      
}
int CheckforCross(double fastMA,double slowMA, double lastFastMA,double lastSlowMA)
{
      static int previous_direction = 0;
      static int current_direction = 0;
      
      //Up Direction = 1
      if(fastMA>slowMA && lastFastMA<lastSlowMA)
      {
         current_direction = 1 ;
         
         
      }
      //Down Direction = 2 
      if(slowMA>fastMA && lastSlowMA<lastFastMA)
      {
         current_direction =2;
      }
      
      //Detect a direction change 
     if(current_direction != previous_direction){
        previous_direction = current_direction;
        return (previous_direction);
     } else {
        return (0);
     }
      
      
}

void closeBuyOrders(int ticket ,bool sslCrossShort ,bool absCrossShort,int cmf ,int baseLineCross )
{

  
      
      //if we have an open position
      if(OrderSelect(ticket,SELECT_BY_TICKET))
      
      //if the order symbol belongs to the chart 
      if(OrderSymbol() == Symbol())
      
      //if we have a buy position 
      if(OrderType() == OP_BUY)
      
      //if the Ask price is half way from take profit 
      if(sslCrossShort||absCrossShort||cmf<0 ||  baseLineCross ==2)
      {
         OrderClose(OrderTicket(),OrderLots(),Bid,3,Purple);
         
      } 
   


}


void closeSellOrders(int ticket,bool sslCrossLong ,bool absCrossLong,int cmf,int baseLineCross )
{
   
      
     
       //if we have an open position
      if(OrderSelect(ticket,SELECT_BY_TICKET))
      
      //if the order symbol belongs to the chart 
      if(OrderSymbol() == Symbol())
      
      //if we have a sell position 
      if(OrderType() == OP_SELL)
      
      
      
      //if the Ask price is half way from take profit 
      if(sslCrossLong || absCrossLong||cmf >0|| baseLineCross == 1)
      {
           OrderClose(OrderTicket(),OrderLots(),Ask,3,Purple);
           
      } 
   


}
void OnDeinit(const int reason)
  {
//---
    Alert("The EA has closed.");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+



void OnTick()
  {
//---
Alert("");
   
    
   double slowMovingSSL = NormalizeDouble(iCustom(NULL,NULL,IndicatorName,SSL_Period,0,1),Digits);// SSL slowMovingAvg Previous day of current day
   double lastSlowMovingSSL =  NormalizeDouble(iCustom(NULL,NULL,IndicatorName,SSL_Period,0,2),Digits); // Last SSL slowMovingAvg of 2nd day
   double fastMovingSSL = NormalizeDouble(iCustom(NULL,NULL,IndicatorName,SSL_Period,1,1),Digits);// SSL fastMovingAvg Previous day of current day
   double lastFastMovingSSL =  NormalizeDouble(iCustom(NULL,NULL,IndicatorName,SSL_Period,1,2),Digits);// Last SSL fastMovingAvg  of 2nd day
   double atrVal = NormalizeDouble(iATR(NULL,0,ATR_Days,0),Digits);// ATR 14 days value
   double cmf = NormalizeDouble(iCustom(NULL,NULL,Indicator1,cmfPeriod,0,0),Digits); // cmf value
   double Currentbaseline = iCustom(NULL,NULL,BaseLine,Baseline_Period,0,0); //baseline value current bar
   double baselinePreviousBar = iCustom(NULL,NULL,BaseLine,Baseline_Period,0,1); // baseline value for previous bar 
   double fastMovingAbs = NormalizeDouble( iCustom(NULL,NULL,absoluteStrength,ABS_MODE,length,smooth,signal,2,1),Digits);
   double lastFastMovingAbs = NormalizeDouble( iCustom(NULL,NULL,absoluteStrength,ABS_MODE,length,smooth,signal,2,2),Digits);
   double slowMovingAbs = NormalizeDouble( iCustom(NULL,NULL,absoluteStrength,ABS_MODE,length,smooth,signal,3,1),Digits);//Absolute strength  red line previous day 
   double lastSlowMovingAbs = NormalizeDouble( iCustom(NULL,NULL,absoluteStrength,ABS_MODE,length,smooth,signal,3,2),Digits);//Absolute strength  red line previous day 
   double greenline = NormalizeDouble(iCustom(NULL,NULL,volume,viscosity,sedimentation,thresHold_lvl,2,0),Digits);
   double greyline = NormalizeDouble(iCustom(NULL,NULL,volume,viscosity,sedimentation,thresHold_lvl,0,0),Digits);
   // Entries variables
   //----------------------------------------------------------- 
   
   //isCrossOverSSL = 1  Up Didrect isCrossOverSSL = 2 Down Direction
   int isCrossOverSSL = CheckforCross(fastMovingSSL,slowMovingSSL,lastFastMovingSSL,lastSlowMovingSSL);
   bool c2AgreesLong = cmf > 0;
   bool c2AgreesShort = cmf < 0;
  
   bool baseLineAgreesLong = iClose(NULL,NULL,1) > baselinePreviousBar;
   bool baseLineAgreesShort = iClose(NULL,NULL,1) < baselinePreviousBar;
    bool isVolume = greenline > greyline;
   // C1 entry Long 
   bool longC1Entry = (fastMovingSSL>slowMovingSSL && lastFastMovingSSL<lastSlowMovingSSL) && isVolume && c2AgreesLong && baseLineAgreesLong;
   bool shortC1Entry = (fastMovingSSL<slowMovingSSL && lastFastMovingSSL>lastSlowMovingSSL) && isVolume && c2AgreesShort&& baseLineAgreesShort;
   bool ssLCrossLong = (fastMovingSSL>slowMovingSSL && lastFastMovingSSL<lastSlowMovingSSL);
   bool sslCrossShort = (fastMovingSSL<slowMovingSSL && lastFastMovingSSL>lastSlowMovingSSL);
     // Exit indicator Absolute Strength 
  // int isCrossOverAbs = CheckforCross(fastMovingAbs,slowMovingAbs,lastFastMovingAbs,lastSlowMovingAbs);
   bool absCrossLong = (fastMovingAbs>slowMovingAbs && lastFastMovingSSL<lastSlowMovingSSL);
   bool absCrossShort = (fastMovingSSL<slowMovingSSL && lastFastMovingSSL>lastSlowMovingSSL);
   // Baseline entry 
    int baseLineCross = CheckBaseLineCross(baselinePreviousBar,iOpen(NULL,NULL,1),iClose(NULL,NULL,1));
    bool baseLineLongEntry = (baseLineCross == 1)  && (fastMovingSSL>slowMovingSSL)&&isVolume;
    bool baseLineShortEntry = (baseLineCross == 2 ) && (slowMovingSSL>fastMovingSSL)&& isVolume;
    
   // Continuation Entry 
    bool longContinuation;
    // short
   bool shortContinuation; 
   
    //checks if there was any C1 signal 7  bars prior
    for(int i=0; i<7; i++)
      {
          double baselinePreviousBarCont = iCustom(NULL,NULL,BaseLine,0,i); // baseline value for previous bar
          bool baselineLong =  iClose(NULL,NULL,i) > baselinePreviousBarCont;
          bool baselineShort = iClose(NULL,NULL,i) < baselinePreviousBarCont;
          double fastMovingSSLCont = NormalizeDouble(iCustom(NULL,NULL,IndicatorName,SSL_Period,1,i),Digits);
          double lastFastMovingSSLCont = NormalizeDouble(iCustom(NULL,NULL,IndicatorName,SSL_Period,1,i+1),Digits);
          double slowMovingSSLCont = NormalizeDouble(iCustom(NULL,NULL,IndicatorName,SSL_Period,0,i),Digits);
          double lastSlowMovingSSLCont = NormalizeDouble(iCustom(NULL,NULL,IndicatorName,SSL_Period,0,i+1),Digits);
          double cmfCont = NormalizeDouble(iCustom(NULL,NULL,Indicator1,cmfPeriod,0,i),Digits); // cmf value
         Print("blpbc"+baselinePreviousBarCont);
         Print("bl long"+baselineLong);
         Print("blpbc"+baselineShort);
         Print("fast MA"+lastFastMovingSSLCont);
         
         
            longContinuation = (fastMovingSSLCont>slowMovingSSLCont && lastFastMovingSSLCont<lastSlowMovingSSLCont)&& fastMovingAbs>slowMovingAbs && baseLineAgreesLong && cmf > 0 && isVolume ;
         
            shortContinuation = (fastMovingSSLCont<slowMovingSSLCont && lastFastMovingSSLCont>lastSlowMovingSSLCont)&& fastMovingSSL<slowMovingSSL && baseLineAgreesShort && cmf < 0 && isVolume;
            
            
         
         
      }
   
    
    
 //+------------------------------------------------------------------+
//| Sending Orders                                 |
//+------------------------------------------------------------------+  
   if(!CheckIfOpenOrdersByMagicNum(magicNum))
   {
 
       if(longC1Entry||baseLineLongEntry||longContinuation)// Long entry 
      {
         Alert("C1 Long Entry ");
         double stopLossPrice = calculateAtrStopLoss(true,Ask,atrStopLossPips(atrVal));
         double takeProfitPrice = calculateAtrTakeProfit(true,Ask,atrTakeProfit(atrVal));
         Alert("Entry Price = " + Ask);
         Alert("Stop Loss Price = " + stopLossPrice);
         Alert("Take Profit Price = " + takeProfitPrice);
         double lotSize = optimalLotSize(atrStopLossPips(atrVal),maxRiskPrc);
   	   orderID =  OrderSend(NULL,OP_BUY,lotSize,Ask,10,stopLossPrice,takeProfitPrice,NULL,magicNum,Blue);
   	   if(highRiskMode) orderID_2 = OrderSend(NULL,OP_BUY,lotSize,Ask,10,stopLossPrice,NULL,NULL,magicNum,Blue);
   
         if(orderID < 0) Alert("order rejected. Order error: " + GetLastError());
         
            
      }

       else if(shortC1Entry||baseLineShortEntry||shortContinuation)  
      {
         Alert("C1 Short Entry ");
         double stopLossPrice = calculateAtrStopLoss(false,Bid,atrStopLossPips(atrVal));
         double takeProfitPrice = calculateAtrTakeProfit(false,Bid,atrTakeProfit(atrVal));
         Alert("Entry Price = " + Bid);
         Alert("Stop Loss Price = " + stopLossPrice);
         Alert("Take Profit Price = " + takeProfitPrice);
         double lotSize = optimalLotSize(atrStopLossPips(atrVal),maxRiskPrc);
   	   orderID =  OrderSend(NULL,OP_SELL,lotSize,Bid,10,stopLossPrice,takeProfitPrice,NULL,magicNum,Red);
         if(highRiskMode)orderID_2 = OrderSend(NULL,OP_SELL,lotSize,Bid,10,stopLossPrice,NULL,NULL,magicNum,Red);
        
         if(orderID < 0) Alert("order rejected. Order error: " + GetLastError());
              
      }
      else
      {
          Alert("The EA hasn't entered and trades.Will check once price has changed");
      }
         
   }
   else // if a trade already exists 
   {
         if( OrderSelect(orderID,SELECT_BY_TICKET)==true )
        {
              int orderType =  OrderType(); //0 = LONG ,1 = SHORT
              int differenceInPips=0;
              bool isBreakEven=false;
              int breakEvenPoint = 0 ;
         // Modify Order 
          
              if(orderType == 0)//  long order  Logic: if ( tpPrice - currentPrice)* digits > orderProfit/2  
              {
                 
                 differenceInPips = NormalizeDouble(OrderTakeProfit()-Ask,Digits)/getPipValue();
                 breakEvenPoint = atrTakeProfit(atrVal)/2;
                 isBreakEven = differenceInPips <breakEvenPoint;
                 Alert("Order differenceInPips: "+differenceInPips);
                  Alert("Order breakEvenPips: "+breakEvenPoint);
                   Alert("Order tp long price : "+OrderTakeProfit());
                  Alert("isBreakEven :"+isBreakEven);
                  if(isBreakEven ) // checks if the difference is half of the tp or more
                  {
                      
                      bool changeOrder = OrderModify(orderID,OrderOpenPrice(),OrderOpenPrice()+ 0.0010,OrderTakeProfit(),0,Yellow);
                     
                  
                     if(changeOrder)
                     {
                       Alert("Order was modified: "+orderID);
                       
                     }
                  }
              
              }
              else if(orderType ==1) // short order
              {
                 differenceInPips = NormalizeDouble(Bid-OrderTakeProfit(),Digits)/getPipValue();
                 breakEvenPoint = atrTakeProfit(atrVal)/2;
                 isBreakEven = differenceInPips <breakEvenPoint;
                 Alert("Order differenceInPips: "+differenceInPips);
                  Alert("Order breakEvenPips: "+breakEvenPoint);
                  Alert("Order tp short price : "+OrderTakeProfit());
                  Alert("Order entry price:" + OrderOpenPrice());
                  Alert("isBreakEven :"+isBreakEven);
                   if(isBreakEven)
                   {
       
                     // order modify set sl to openprice + 0.0010
                     bool changeOrder = OrderModify(orderID,OrderOpenPrice(),OrderOpenPrice()- 0.00010,OrderTakeProfit(),0,Yellow);
                     
                     if(changeOrder)
                     {
                       Alert("Order was modified: "+orderID);
                     }
                   }
              }
         
     if(highRiskMode && OrderSelect(orderID,SELECT_BY_TICKET)==true)
       {
              int orderType =  OrderType(); //0 = LONG ,1 = SHORT
              int differenceInPips=0;
              bool isBreakEven=false;
              int breakEvenPoint = 0 ;
              
              
          //    Modify Order 
           if(orderType == 0)//  long order  Logic: if ( tpPrice - currentPrice)* digits > orderProfit/2  
              {
                differenceInPips = NormalizeDouble(OrderTakeProfit()-Ask,Digits)/getPipValue();
                 breakEvenPoint = atrTakeProfit(atrVal)/2;
                 isBreakEven = differenceInPips <breakEvenPoint;
                 Alert("Order differenceInPips hr : "+differenceInPips);
                  Alert("Order breakEvenPips hr : "+breakEvenPoint);
                   Alert("Order tp long price hr  : "+OrderTakeProfit());
                  Alert("isBreakEven hr :"+isBreakEven);
                
                  if(isBreakEven ) // checks if the difference is half of the tp or more
                  {
                     // order modify set sl to openprice + 0.0010
                      if(OrderSelect(orderID_2,SELECT_BY_TICKET)==true)
                      {
                         bool changeOrder = OrderModify(orderID_2,OrderOpenPrice(),OrderOpenPrice()+ 0.0010,NULL,0,Yellow);
                         Alert("Order was modified: "+orderID_2);
                      }
                     
                  }
              
              }
               else if(orderType ==1) // short order
              {
                   
                  
                   if(isBreakEven)
                   {
                     differenceInPips = NormalizeDouble(Bid-OrderTakeProfit(),Digits)/getPipValue();
                    breakEvenPoint = atrTakeProfit(atrVal)/2;
                    isBreakEven = differenceInPips <breakEvenPoint;
                    Alert("Order differenceInPips hr: "+differenceInPips);
                     Alert("Order breakEvenPips hr: "+breakEvenPoint);
                     Alert("Order tp short price hr : "+OrderTakeProfit());
                     Alert("Order entry price hr :" + OrderOpenPrice());
                     Alert("isBreakEven hr :"+isBreakEven);
                     if(OrderSelect(orderID_2,SELECT_BY_TICKET)==true)
                      {
                         bool changeOrder = OrderModify(orderID,OrderOpenPrice(),OrderOpenPrice()- 0.00010,NULL,0,Yellow);
                         Alert("Order was modified: "+orderID_2);
                         
                         
                      }
                     
                   }
              }
       
         
       }
        //close orders
        closeBuyOrders(orderID,sslCrossShort,absCrossShort,cmf,baseLineCross);
        closeSellOrders(orderID,ssLCrossLong,absCrossLong,cmf,baseLineCross);
        closeBuyOrders(orderID_2,sslCrossShort,absCrossShort,cmf,baseLineCross);
        closeSellOrders(orderID_2,ssLCrossLong,absCrossLong,cmf,baseLineCross);
       }
      
    }
    
  }
//+------------------------------------------------------------------+
