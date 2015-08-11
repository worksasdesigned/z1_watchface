using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.Application as App;
using Toybox.Math as Math;


var fast_updates = true;  // check if user looks at his fenix3 is set in onhide() at the end of source code
var breite, hoehe, device_settings;
var prim_color = Gfx.COLOR_RED;  // primary color
var sec_color = Gfx.COLOR_DK_RED; // secondary color
var pic_steps, pic_way, pic_kcal;
var fenix_purble = 0x5500AA ; // fenix PURBLE is not Gfx.COLOR_PURBLE Arrg! Thx Garmin!

//############################################################################################
//
//
//
// !!!!!!!!!!!!!!!!!!!  DO  N O T CHANGE THIS WATCHFACE!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!!  AND PUBLISH IT AFTERWARDS      !!!!!!!!!!!!!!!!!!
// YOU CAN COPY WHAT EVER YOU WANT, BUT YOU HAVE TO CREATE A   N E  W  PROGRAMM !!!!!!!!!
// ELSE THE PROGRAMM ID WILL MESS UP YOUR AND MY APP (doublicates in CONNECTIQ) 
// 
//
//
//
//  sure.....  code might be inefficent .. how cares...it works and thats enough for me ;-)
//  i'm programming a watchface - not a procedure for NASA mars-mission.
//
//  structure is quite simple and a hell of "spaghetti-code" but you'll find :
//  1. read device_setting eg. 24h mode or metric/imperial UNITS
//  2. draw circles, lines, polygons, filled circles and setPenwidth
//  3. create and call functions
//  4. calculate X,Y Position on a circle around 109,109
//  5. add 2 tiny pictures
//  6. read steps, daily stepsGoal 
//  7. read date 
// 
// questions? --> ispamsammler@googlemail.com
//#############################################################################################
class Z1_blueView extends Ui.WatchFace {

    //! Load your resources here
    function onLayout(dc) {
     breite = dc.getWidth();
     hoehe = dc.getHeight();
     device_settings = Sys.getDeviceSettings(); // general device settings like 24or12h mode

     
     // Bilder laden
     pic_steps = null;  // free memory
     pic_way = null;    // free memory
     pic_kcal = null;   // free memory 
     pic_steps = Ui.loadResource(Rez.Drawables.id_steps); // load pictur from resources.xml    
     pic_way = Ui.loadResource(Rez.Drawables.id_way);    // load pictur from resources.xml
     pic_kcal = Ui.loadResource(Rez.Drawables.id_kcal);  // load pictur from resources.xml   
     }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
    }

    //! Update the view
    function onUpdate(dc) {
        // clear the screen, just draw a black rectangle
    	dc.setColor( Gfx.COLOR_BLACK,  Gfx.COLOR_BLACK);
    	dc.fillRectangle(0, 0, breite, hoehe);
    	dc.clear();
    
        //READ TIME, DATE and stuff like that
        var clockTime = Sys.getClockTime();
        var dateStrings = Time.Gregorian.info( Time.now(), Time.FORMAT_MEDIUM);
        var dateStrings_s = Time.Gregorian.info( Time.now(), Time.FORMAT_SHORT);
        var hour, min, time, day, sec, month;
        day  = dateStrings.day;
        month  = dateStrings.month;
        min  = clockTime.min;
        hour = clockTime.hour;
        sec  = clockTime.sec;
        
        // READ activity data (steps, movebar level)
        var activity = ActivityMonitor.getInfo();
        var moveBarLevel = activity.moveBarLevel;
        var stepsGoal = activity.stepGoal;
        var stepsLive = activity.steps; 
        var kcal     = activity.calories;
        var km       = activity.distance.toFloat() / 100 / 1000; // distance is saved as cm --> / 100 / 1000 --> km
        var km_txt = "km";            
        if (device_settings.distanceUnits){//is watch set to IMPERIAL-Units?  km--> miles
            km = km.toFloat() * 0.62137;
            km_txt = "mi";
         }
         km = km.format("%2.1f");     // formatting km/mi to 2numbers + 1 digit
                     
        var activproz = stepsLive / stepsGoal.toFloat() * 100; // % of your daily goal achived            
             //color the entire watchface depending of your daily goal
            if (activproz >= 100) {  // finished! --> green
               prim_color = Gfx.COLOR_GREEN; 
               sec_color  = Gfx.COLOR_DK_GREEN;
            } else if (activproz >= 75) {      // 75% --> blue           
               prim_color = Gfx.COLOR_BLUE; 
               sec_color  = Gfx.COLOR_DK_BLUE;
            } else if (activproz >= 50) {      //50% --> YELLOW            
               prim_color = Gfx.COLOR_YELLOW; 
               sec_color  = Gfx.COLOR_ORANGE;    
            } else if (activproz >= 33) {      // 33% --> PURBLE           
               prim_color = Gfx.COLOR_PINK; 
               sec_color  = fenix_purble;
            } else {               
               prim_color = Gfx.COLOR_RED;    // 0-33% RED
               sec_color  = Gfx.COLOR_DK_RED;
            }
                    
            // sleep mode --> GRAY
            if (activity.isSleepMode){ // is watch in sleep mode? --> color it gray              
               prim_color = Gfx.COLOR_LT_GRAY; 
               sec_color  = Gfx.COLOR_DK_GRAY;
            }
        // draw general watchface layout

        //Draw thin 60 Minute lines
        //       dc,amount of fragments of 360circle, outer radian, inner radian, color, 360degree
        draw_min(dc,60,1,(hoehe/2),(hoehe/2-12), prim_color,360); 
        //if user looks at his watch: draw the moving second "hand"
        if (fast_updates){
            drawsec(dc,100, prim_color, sec_color);    
        }
        
        // draw the big white 5 Min lines
        //       dc,amount of fragments of 360circle, outer radian, inner radian, color, 360degree
        draw_min(dc,12,3,(hoehe/2),(hoehe/2-20), Gfx.COLOR_WHITE,360);  
		
		// analog hour+minute "finger" 
		draw_watch_finger(dc,hour,min,Gfx.COLOR_WHITE, 6, 3, hoehe/2, (0.75*hoehe/2), (0.9*hoehe/2) );
		
		// major circle
		dc.setColor( sec_color,  sec_color); // set color 
		dc.fillCircle(breite/2, hoehe/2, hoehe*2/7); // draw filled circle

        //depending on movebar-status --> draw a colored circle around the major circle
               if (moveBarLevel >=5) { // user very inactive 
                    if (sec % 2 == 1){ // change between red and dk_red every second              
                     dc.setColor( Gfx.COLOR_DK_RED, Gfx.COLOR_DK_RED);
                    }else{dc.setColor( Gfx.COLOR_RED, Gfx.COLOR_RED);
                    }
                }else if (moveBarLevel >=4) {     // user inactive           
                    dc.setColor( Gfx.COLOR_RED, Gfx.COLOR_RED);
                }else if (moveBarLevel >=3) {    // user a bit inactive            
                    dc.setColor( Gfx.COLOR_ORANGE, Gfx.COLOR_ORANGE);    
                }else if (moveBarLevel >=2) {   // less inactive             
                    dc.setColor( Gfx.COLOR_YELLOW, Gfx.COLOR_YELLOW);
                }else if (moveBarLevel >=1) { // just started to be inactive
                    dc.setColor( Gfx.COLOR_GREEN, Gfx.COLOR_GRAY);                    
                } 
                 
                        
        dc.drawCircle(breite/2, hoehe/2, hoehe*2/7); // circle around major circle
        dc.drawCircle(breite/2-breite/5, hoehe/2-hoehe/6, 23); //circle around tiny date-circle
        // draw tiny date-circle
        dc.setColor( Gfx.COLOR_WHITE,  Gfx.COLOR_WHITE);
        dc.fillCircle(breite/2-breite/5, hoehe/2-hoehe/6, 23);

        //write date--> 11 (SHORT) Aug (MEDIUM)
		dc.setColor( Gfx.COLOR_BLACK,  Gfx.COLOR_TRANSPARENT);
        dc.drawText(breite/2-breite/5, hoehe/2-hoehe/6-20, Gfx.FONT_TINY, day.toString(), Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(breite/2-breite/5, hoehe/2-hoehe/6-4, Gfx.FONT_TINY, month.toString(), Gfx.TEXT_JUSTIFY_CENTER);
        
        if( !device_settings.is24Hour ) { // AM/PM if watch is in 12hour Mode --> US
        dc.setColor( Gfx.COLOR_WHITE,  Gfx.COLOR_TRANSPARENT);
           if (hour >= 12) { 
                hour = hour - 12;
                dc.drawText(breite/2+2, hoehe/2 + 13 , Gfx.FONT_SMALL , "pm" , Gfx.TEXT_JUSTIFY_CENTER );
                }
            else{  
                dc.drawText(breite/2+5, hoehe/2 +13, Gfx.FONT_SMALL , "am" , Gfx.TEXT_JUSTIFY_CENTER );                
            }
            if (hour == 0) {hour = 12;}    
            hour  = Lang.format("$1$",[hour.format("%2d")]);
            min   = Lang.format("$1$",[min.format("%02d")]); 
        }
        else {            
            hour  = Lang.format("$1$",[hour.format("%02d")]);
            min   = Lang.format("$1$",[min.format("%02d")]);
        }
        // draw hour + minutes + : as letters
		dc.setColor( Gfx.COLOR_WHITE,  Gfx.COLOR_TRANSPARENT);
		dc.drawText(breite/2-5, hoehe/2, Gfx.FONT_LARGE, hour.toString(), Gfx.TEXT_JUSTIFY_RIGHT|Gfx.TEXT_JUSTIFY_VCENTER);
        dc.drawText(breite/2, hoehe/2, Gfx.FONT_LARGE, ":", Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
        dc.drawText(breite/2+5, hoehe/2, Gfx.FONT_LARGE, min.toString(), Gfx.TEXT_JUSTIFY_LEFT|Gfx.TEXT_JUSTIFY_VCENTER);
        
        //USER is watching the watch -> show all information
        if (fast_updates){	        
			sec   = Lang.format("$1$",[sec.format("%02d")]); // format seconds to "01,02,03,..10" instead of 1,2,3..10
			dc.setColor( Gfx.COLOR_WHITE,  Gfx.COLOR_TRANSPARENT);
			dc.drawText(breite/2+5+32,(hoehe/2+2), Gfx.FONT_MEDIUM, sec.toString(),Gfx.TEXT_JUSTIFY_LEFT|Gfx.TEXT_JUSTIFY_VCENTER);
			// Battery
			drawbatt(dc, breite/2 - 16, hoehe/2 + (hoehe*2/7) - 16); // function, source below
			//steps, km/miles and depending icons
            dc.setColor( Gfx.COLOR_WHITE,  Gfx.COLOR_TRANSPARENT);
            dc.drawBitmap(breite/2-3-14, 64, pic_way); //way     
			//dc.drawBitmap(breite/2-3-13, 69, pic_kcal); // kcal    
            dc.drawBitmap(breite/2-3-15 , 80, pic_steps); // steps
            dc.drawText(breite/2 +3, 59, Gfx.FONT_XTINY, km.toString() + km_txt.toString(), Gfx.TEXT_JUSTIFY_LEFT);
            //dc.drawText(breite/2 +3, 66, Gfx.FONT_XTINY, kcal.toString(), Gfx.TEXT_JUSTIFY_LEFT); 
            dc.drawText(breite/2 +3, 75, Gfx.FONT_XTINY, stepsLive.toString(), Gfx.TEXT_JUSTIFY_LEFT);    
        }
        
    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
        fast_updates = false;
        Ui.requestUpdate();
    }

    //! The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
        fast_updates = true;    // indicator that everythings goes fast now (fast = 1 sec per update)    
        Ui.requestUpdate();
    }

    //! Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
        fast_updates = false;
        Ui.requestUpdate();
    }
    
    // well - math with sin & cos is quite a long time ago ;-)
    // draws a "moving" second indicator as 5 colored polygons
    function drawsec(dc, rad2){  
            var dateInfo = Time.Gregorian.info( Time.now(), Time.FORMAT_SHORT );
            var sec  = dateInfo.sec;            
            for (var k = 0; k <=59; k++){
            if ( ( k >= ( sec - 4 ) ) && ( k<=sec)){    
                dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE);
                var xx, xx2, yy, yy2,kxx,kyy,kxx2,kyy2, winkel, slim;
                winkel = 180 +k * -6;
                slim = 2;
                //      1 Polygon moving around a bigger and smaller circle
                //        xx/yy----------------xx2/yy2
                //          \                     /
                //           \                   /          --> 
                //            \                 / 
                //         kxx/kyy---------kxx2/kyy2   
                yy  = 1+dc.getWidth()/2 * (1+Math.cos(Math.PI*(winkel-2)/180));
                yy2 = 1+dc.getWidth()/2 * (1+Math.cos(Math.PI*(winkel+3)/180));  
                xx  = 1+ dc.getWidth()/2 * (1+Math.sin(Math.PI*(winkel-2)/180));
                xx2 = 1+ dc.getWidth()/2 * (1+Math.sin(Math.PI*(winkel+3)/180)); 
                kyy  = 1+dc.getWidth()/2 + rad2 * (Math.cos(Math.PI*(winkel-2)/180)); 
                kyy2 = 1+dc.getWidth()/2 + rad2 * (Math.cos(Math.PI*(winkel+3)/180));  
                kxx  = 1+ dc.getWidth()/2 + rad2 * (Math.sin(Math.PI*(winkel-2)/180));
                kxx2 = 1+ dc.getWidth()/2 + rad2 * (Math.sin(Math.PI*(winkel+3)/180));                               
                if ( k == sec ){dc.setColor(sec_color, sec_color); }
                if ( k == sec - 1 ){dc.setColor(prim_color, prim_color);}
                if ( k == sec - 2 ){dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_DK_GRAY);}
                if ( k == sec - 3 ){dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_LT_GRAY);}
                if ( k == sec - 4 ){dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE);}    
                if (yy > 180) {yy = yy -1; yy2 = yy2 -1;} 
                // finally draw the ploygon with 4 coordinates
                dc.fillPolygon([[kxx, kyy], [xx, yy] ,[xx2,yy2],[kxx2, kyy2]]);
            }  
            }           
                
    }
    
    // draw the analog watch fingers
                         //    dc, 14, 23 , COLOR, penWidhth hour, PenWidthmin, inner radian, hour radian, minite radian           
    function draw_watch_finger(dc,hour, min, color, hourpen, minpen, rad1, radhour, radmin){
    	var xx, x, yy, y, winkel;
    	//DRAW HOUR FINGER	
		dc.setColor( color,  color); // set color
		winkel = 180 + hour%12 * -30; // in case you want the hour-finger to point  exacteley to 11 at 11:xx o'clock
        winkel = winkel.toFloat() - ((min.toFloat()/60)*30); // if not --> move the hour finger a little bit more towars 12 o'clock
		x = rad1;
		y = rad1;
		xx = rad1 + radhour * ( Math.sin(Math.PI*(winkel.toFloat()/180))); // sin&cos in radian not degree!
		yy = rad1 + radhour * ( Math.cos(Math.PI*(winkel.toFloat()/180))); // sin&cos in radian not degree!
		dc.setPenWidth(hourpen);
		dc.drawLine(x, y, xx, yy); // draw hour finger
		//Sys.println("xx=" + xx + " yy=" + yy + " x=" + x + " y=" +y + " winkel=" + winkel); // here you can see the sin&cos calculation
		//Sys.println(hour + ":" + min + " o'clock");
		
		// now draw minute finger
		x = rad1;
		y = rad1;
		winkel = 180 + min * -6; // 6° per Minute 
		xx = rad1 + radmin * ( Math.sin(Math.PI*(winkel.toFloat()/180)));  // sin&cos in radian not degree!
		yy = rad1 + radmin * ( Math.cos(Math.PI*(winkel.toFloat()/180)));  // sin&cos in radian not degree!
		dc.setPenWidth(minpen); 
		dc.drawLine(x, y, xx, yy); // draw minute finger
		//Sys.println("xx=" + xx + " yy=" + yy + " x=" + x + " y=" +y + " winkel=" + winkel);
		//Sys.println(radmin);

    }
    
    // draw minute and 5 minute lines
    // at the beginning i used this for drawing the second in fast_updates mode. --> maxdeg
    // not anymore, but code still there
    function draw_min(dc,divisor,pen,rad1,rad2, color, maxdeg){  
            var xx, x, yy, y, winkel;
            winkel = 0;
            dc.setPenWidth(pen);
            dc.setColor( Gfx.COLOR_WHITE,  color);
            for (var k = 0; k <divisor; k++){
                winkel =   k * (360/divisor);
                winkel = winkel.toFloat();
                if (winkel < maxdeg){
	                yy  = rad1 + rad2 * ( Math.cos(Math.PI*((180+-1*winkel.toFloat())/180)));
	                y = rad1 + rad1 * ( Math.cos(Math.PI*((180+-1*winkel.toFloat())/180)));  
	                xx  = rad1 + rad2 * ( Math.sin(Math.PI*((180+-1*winkel.toFloat())/180)));
	                x = rad1 + rad1 *  ( Math.sin(Math.PI*((180+-1*winkel.toFloat())/180)));
	                // draw line
					dc.setColor( color,  color);
					dc.drawLine(x, y, xx, yy);
				}                
             }
            dc.setPenWidth(1);
    }
  
  // draw the battery
//                 dc, positionx , position y)  
 function drawbatt(dc,batx,baty){
              // Batterie neu
              var batt = Sys.getSystemStats().battery; // get battery status
              batt = batt.toNumber(); // safety first --> set it to integer
              dc.setPenWidth(1);
              batx = batx.toNumber();
              baty = baty.toNumber();
              
              // draw boarder 
              dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE); 
              dc.fillRectangle(batx, baty, 31, 12); // white area BODY
              dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_DK_GRAY); 
              dc.fillRectangle(batx + 31, baty +3, 3, 6); //  BOBBL
              dc.drawRectangle(batx, baty, 31, 12); // frame
              //draw green / colored fill-level
               
               if (batt >= 50) { // draw big block if batt > 50%
                dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_GREEN);
                dc.fillRectangle(batx +1, baty+1, 14, 10);
                if (batt >= 60){dc.fillRectangle(batx+16, baty+1, 2, 10);} // add tiny 60% bar
                if (batt >= 70){dc.fillRectangle(batx+19, baty+1, 2, 10);} // add tiny 70% bar
                if (batt >= 80){dc.fillRectangle(batx+22, baty+1, 2, 10);} // add tiny 80% bar
                if (batt >= 90){dc.fillRectangle(batx+25, baty+1, 2, 10);} // add tiny 90% bar
                if (batt >= 100){dc.fillRectangle(batx+1, baty+1, 29, 10); // add 100% bar (covers 60-90% bar)
                   dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
                   dc.drawText(batx+3 ,  baty+4 , Gfx.FONT_XTINY, "100" , Gfx.TEXT_JUSTIFY_LEFT|Gfx.TEXT_JUSTIFY_VCENTER); // write 100% fully charged 
                }
               }else { // battery < 50% switch design 
                dc.setColor(Gfx.COLOR_DK_GREEN, Gfx.COLOR_DK_GREEN);
                if (batt >= 40){dc.fillRectangle(batx+12, baty+1, 4, 10);}  // add tiny 40% bar green
                dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_YELLOW);
                if (batt >= 30){dc.fillRectangle(batx+8, baty+1, 4, 10);}    // add tiny 30% bar yellow 
                dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_ORANGE);
                if (batt >= 20){dc.fillRectangle(batx+5, baty+1, 4, 10);}   // add tiny 20% bar red
                dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
                if (batt >= 11){dc.fillRectangle(batx+1, baty+1, 4, 10);} // 10% Rest
                else{
                 if (sec %2 == 1){    // blink very second LOW!
                    dc.fillRectangle(batx+1, baty+1, 3, 10);
                 }else{
                   dc.drawText(batx+3 ,  baty+5 , Gfx.FONT_XTINY, "LOW" , Gfx.TEXT_JUSTIFY_LEFT|Gfx.TEXT_JUSTIFY_VCENTER);  
                 }
                }
                if (batt >=11) { // write Batt text between 49% & 11%
                    dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
                    dc.drawText(batx+15 ,  baty+5 , Gfx.FONT_XTINY, batt.toString() , Gfx.TEXT_JUSTIFY_LEFT|Gfx.TEXT_JUSTIFY_VCENTER);
                 } 
                } // End BATT
} // End drawbattfunction    

}
