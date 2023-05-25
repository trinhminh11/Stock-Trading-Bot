#include<Trade/Trade.mqh>


#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"


input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;
//input double Pip_Value = 1000;
input bool Lot_Fixed = true;
input double Lots = 0.05;

input double trailing_start = 5;
input double trailing_amount = 1;
input double open_start = 10;
input double TP = 10;
input double peak_open_diff = 3;
input double Balance_step = 200;

CTrade trade;
int totalBars;
bool newbar = true;
double last_ask;
double last_bid;

int OnInit(){
   
   totalBars = iBars(_Symbol, Timeframe);
   last_ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   last_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason){
//---
   
  }

void OnTick(){
   double Lot = Lots;
   
   if (Lot_Fixed == false){
      double Balance = AccountInfoDouble(ACCOUNT_BALANCE);
      Lot = round(Balance/Balance_step)*0.01;

   }
   
   int bars = iBars(_Symbol, Timeframe);
   double  open = iOpen(_Symbol,Timeframe,0 );
   double close = iClose(_Symbol,Timeframe,0);
   double  high = iHigh(_Symbol,Timeframe,0);
   double   low = iLow(_Symbol,Timeframe,0);
   double current_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double current_ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   int total = PositionsTotal();
   for(int pos=0; pos<total; pos++) { 
         ulong ticket = PositionGetTicket(pos);
         
         if(PositionSelectByTicket(ticket)){
            double posSL = PositionGetDouble(POSITION_SL);
            double posTP = PositionGetDouble(POSITION_TP);
            double posLots = PositionGetDouble(POSITION_VOLUME);
            double Current_Price = PositionGetDouble(POSITION_PRICE_CURRENT);
            double Open_Price = PositionGetDouble(POSITION_PRICE_OPEN);
            string Pos_Comment = PositionGetString(POSITION_COMMENT);
           
            

               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                  if(current_ask >= Open_Price + trailing_start){
                     if (posSL + trailing_amount < Current_Price){
                        trade.PositionModify(ticket, posSL + trailing_amount, posTP);
                     }
                  }
               }
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                  if(current_bid <= Open_Price - trailing_start){
                     if (posSL - trailing_amount > Current_Price){
                        trade.PositionModify(ticket, posSL - trailing_amount, posTP);
                     }
                  }
               }
            
         }
      }
  
      
   if (current_ask - open > open_start && newbar && open - low < peak_open_diff){
      trade.Buy(Lot,_Symbol, current_ask, open, current_ask + TP, "never");
      newbar = false;
   }
   if (open - current_bid > open_start && newbar && high - open < peak_open_diff){
      trade.Sell(Lot,_Symbol, current_bid, open, current_bid - TP, "never");
      newbar = false;
   }
   if(bars != totalBars){
      totalBars = bars;
      newbar = true;
   }
   
   last_ask = current_ask;
   last_bid = current_bid;
  
}