using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.Application as App;
using Toybox.Math as Math;


var fast_updates = true;
var breite, hoehe, device_settings;
var prim_color = Gfx.COLOR_RED;
var sec_color = Gfx.COLOR_DK_RED;
var pic_steps, pic_way, pic_kcal;

//############################################################################################
//
//
//
// !!!!!!!!!!!!!!!!!!!  DO NOT CHANGE THIS WATCHFACE!!!!!!!!!!!!!!!!!!
//
//
// YOU CAN COPY WHAT EVER YOU WANT, BUT YOU HAVE TO CREATE A   N E  W  PROGRAMM !!!!!!!!!
// ELSE THE PROGRAMM ID WILL MESS UP YOUR AND MY APP (doublicates in CONNECTIQ) 
// questions? --> ispamsammler@googlemail.com
//
//
//#############################################################################################
class Z1_blueView extends Ui.WatchFace {

    //! Load your resources here
    function onLayout(dc) {
     breite = dc.getWidth();
     hoehe = dc.getHeight();
     device_settings = Sys.getDeviceSettings();

     
     // Bilder laden
     pic_steps = null;
     pic_way = null;
     pic_kcal = null;   
     pic_steps = Ui.loadResource(Rez.Drawables.id_steps);    
     pic_way = Ui.loadResource(Rez.Drawables.id_way);
     pic_kcal = Ui.loadResource(Rez.Drawables.id_kcal);
     }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
    }

    //! Update the view
    function onUpdate(dc) {
    	dc.setColor( Gfx.COLOR_BLACK,  Gfx.COLOR_BLACK);
    	dc.fillRectangle(0, 0, breite, hoehe);
    	dc.clear();
    
        // Uhrzeit auslesen
        var clockTime = Sys.getClockTime();
        var dateStrings = Time.Gregorian.info( Time.now(), Time.FORMAT_MEDIUM);
        var dateStrings_s = Time.Gregorian.info( Time.now(), Time.FORMAT_SHORT);
        var hour, min, time, day, sec, month;
        day  = dateStrings.day;
        month  = dateStrings.month;
        min  = clockTime.min;
        hour = clockTime.hour;
        sec  = clockTime.sec;
        
        // Activity auslesen
        var activity = ActivityMonitor.getInfo();
        var moveBarLevel = activity.moveBarLevel;
        var stepsGoal = activity.stepGoal;
        var stepsLive = activity.steps; 
        var kcal     = activity.calories;
        var km       = activity.distance.toFloat() / 100 / 1000;
        var km_txt = "km";
            //km       = Lang.format("%4.2f",[min.format("%02d")]);
        if (device_settings.distanceUnits){// meilen statt km
            km = km.toFloat() * 0.62137;
            km_txt = "mi";
         }
         km = km.format("%2.1f");    
                     
        var activproz = stepsLive / stepsGoal.toFloat() * 100;
            
             //Uhr je nach activityprozent einfärben
            if (activproz >= 100) {
               prim_color = Gfx.COLOR_GREEN; 
               sec_color  = Gfx.COLOR_DK_GREEN;
            } else if (activproz >= 75) {                
               prim_color = Gfx.COLOR_BLUE; 
               sec_color  = Gfx.COLOR_DK_BLUE;
            } else if (activproz >= 50) {                
               prim_color = Gfx.COLOR_YELLOW; 
               sec_color  = Gfx.COLOR_ORANGE;    
            } else if (activproz >= 13) {                
               prim_color = Gfx.COLOR_PINK; 
               sec_color  = Gfx.COLOR_PURPLE;
            } else {               
               prim_color = Gfx.COLOR_RED; 
               sec_color  = Gfx.COLOR_DK_RED;
            }
                    
            // sleep mode grau
            if (activity.isSleepMode){             
               prim_color = Gfx.COLOR_LT_GRAY; 
               sec_color  = Gfx.COLOR_DK_GRAY;
            }
        // Layout zeichnen
        draw_min(dc,60,1,(hoehe/2),(hoehe/2-12), prim_color,360); // minutenstriche
        //Sekundenpolygon zeichnen (über seundenstriche, unter 5min Strichen)
        if (fast_updates){
            drawsec(dc,100, prim_color, sec_color);    
        }
        draw_min(dc,12,3,(hoehe/2),(hoehe/2-20), Gfx.COLOR_WHITE,360);  // 5 Minuten Striche
		// Stundenzeiger
		draw_watch_finger(dc,hour,min,Gfx.COLOR_WHITE, 6, 3, hoehe/2, (0.75*hoehe/2), (0.9*hoehe/2) );
		// hauptkreis
		dc.setColor( sec_color,  sec_color);
		dc.fillCircle(breite/2, hoehe/2, hoehe*2/7);
        // datumskreis
        dc.setColor( Gfx.COLOR_WHITE,  Gfx.COLOR_WHITE);
        dc.fillCircle(breite/2-breite/5, hoehe/2-hoehe/6, 23);
       
        //movebar kreis je nach Stufe einfärben
               if (moveBarLevel >=5) { 
                    if (sec % 2 == 1){               
                     dc.setColor( Gfx.COLOR_DK_RED, Gfx.COLOR_DK_RED);
                    }else{dc.setColor( Gfx.COLOR_RED, Gfx.COLOR_RED);
                    }
                }else if (moveBarLevel >=4) {                
                    dc.setColor( Gfx.COLOR_RED, Gfx.COLOR_RED);
                }else if (moveBarLevel >=3) {                
                    dc.setColor( Gfx.COLOR_ORANGE, Gfx.COLOR_ORANGE);    
                }else if (moveBarLevel >=2) {                
                    dc.setColor( Gfx.COLOR_YELLOW, Gfx.COLOR_YELLOW);
                }else if (moveBarLevel >=1) {
                    dc.setColor( Gfx.COLOR_GREEN, Gfx.COLOR_LT_GRAY);                    
                 } 
        dc.drawCircle(breite/2-breite/5, hoehe/2-hoehe/6, 23); // kreis um datumskreis
        dc.drawCircle(breite/2, hoehe/2, hoehe*2/7); // kreis um hauptkreis

        //datum schreiben
		dc.setColor( Gfx.COLOR_BLACK,  Gfx.COLOR_TRANSPARENT);
        dc.drawText(breite/2-breite/5, hoehe/2-hoehe/6-20, Gfx.FONT_TINY, day.toString(), Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(breite/2-breite/5, hoehe/2-hoehe/6-4, Gfx.FONT_TINY, month.toString(), Gfx.TEXT_JUSTIFY_CENTER);
        
        if( !device_settings.is24Hour ) { // AM/PM anzeige
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
        // Stunde // Minuten schreiben
		dc.setColor( Gfx.COLOR_WHITE,  Gfx.COLOR_TRANSPARENT);
		dc.drawText(breite/2-5, hoehe/2, Gfx.FONT_LARGE, hour.toString(), Gfx.TEXT_JUSTIFY_RIGHT|Gfx.TEXT_JUSTIFY_VCENTER);
        dc.drawText(breite/2, hoehe/2, Gfx.FONT_LARGE, ":", Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
        dc.drawText(breite/2+5, hoehe/2, Gfx.FONT_LARGE, min.toString(), Gfx.TEXT_JUSTIFY_LEFT|Gfx.TEXT_JUSTIFY_VCENTER);
        
        //Man schaut auf die Uhr alle daten anzeigen
        if (fast_updates){
	        //draw_min(dc,60,12,(hoehe/2),(hoehe/2-4), sec_color,(6*sec)); // aktuelle sekundenanzeige
			sec   = Lang.format("$1$",[sec.format("%02d")]);
			dc.setColor( Gfx.COLOR_WHITE,  Gfx.COLOR_TRANSPARENT);
			dc.drawText(breite/2+5+32,(hoehe/2+2), Gfx.FONT_MEDIUM, sec.toString(),Gfx.TEXT_JUSTIFY_LEFT|Gfx.TEXT_JUSTIFY_VCENTER);
			// Batterie
			drawbatt(dc, breite/2 - 16, hoehe/2 + (hoehe*2/7) - 16);
			//steps und Bilder
            dc.setColor( Gfx.COLOR_WHITE,  Gfx.COLOR_TRANSPARENT);
            dc.drawBitmap(breite/2-3-14, 64, pic_way); //way zeichnen    
			//dc.drawBitmap(breite/2-3-13, 69, pic_kcal); // kcal    
            dc.drawBitmap(breite/2-3-15 , 81, pic_steps); // steps
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
        fast_updates = true;        
        Ui.requestUpdate();
    }

    //! Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
        fast_updates = false;
         Ui.requestUpdate();
    }
    
    function drawsec(dc, rad2){  
            var dateInfo = Time.Gregorian.info( Time.now(), Time.FORMAT_SHORT );
            var sec  = dateInfo.sec;            
            for (var k = 0; k <=59; k++){
            if ( ( k >= ( sec - 4 ) ) && ( k<=sec)){    
                dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE);
                var xx, xx2, yy, yy2,kxx,kyy,kxx2,kyy2, winkel, slim;
                winkel = 180 +k * -6;
                slim = 2;
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
                dc.fillPolygon([[kxx, kyy], [xx, yy] ,[xx2,yy2],[kxx2, kyy2]]);
            }  
            }           
                
    }
    
    function draw_watch_finger(dc,hour, min, color, hourpen, minpen, rad1, radhour, radmin){
    	var xx, x, yy, y, winkel;
    	//erstmal Stunde zeichnen
	
		dc.setColor( color,  color);
		winkel = 180 + hour%12 * -30; //exakte Stunden (ganze Stundenzeiger)
        winkel = winkel.toFloat() - ((min.toFloat()/60)*30); // anteilige Korrektur des Winkels 
		x = rad1;
		y = rad1;
		xx = rad1 + radhour * ( Math.sin(Math.PI*(winkel.toFloat()/180)));
		yy = rad1 + radhour * ( Math.cos(Math.PI*(winkel.toFloat()/180)));
		dc.setPenWidth(hourpen);
		dc.drawLine(x, y, xx, yy);
		//Sys.println("xx=" + xx + " yy=" + yy + " x=" + x + " y=" +y + " winkel=" + winkel);
		//Sys.println(hour + " " + min);
		// jetzt Minute
		x = rad1;
		y = rad1;
		winkel = 180 + min * -6;
		xx = rad1 + radmin * ( Math.sin(Math.PI*(winkel.toFloat()/180)));
		yy = rad1 + radmin * ( Math.cos(Math.PI*(winkel.toFloat()/180)));
		dc.setPenWidth(minpen);
		dc.drawLine(x, y, xx, yy);
		//Sys.println("xx=" + xx + " yy=" + yy + " x=" + x + " y=" +y + " winkel=" + winkel);
		//Sys.println(radmin);

    }
    
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
	                //Polygon zeichnen
					dc.setColor( color,  color);
					dc.drawLine(x, y, xx, yy);
				}                
             }
            dc.setPenWidth(1);
    }
    
 function drawbatt(dc,batx,baty){
              // Batterie neu
              var batt = Sys.getSystemStats().battery;
              batt = batt.toNumber();
              dc.setPenWidth(1);
              batx = batx.toNumber();
              baty = baty.toNumber();
              //var batx, baty;
              //batx = 170;
              //baty = 136;  
              // Rahmen zeichnen  
              dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE); 
              dc.fillRectangle(batx, baty, 31, 12); // weißer Bereich BODY
              dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_DK_GRAY); 
              dc.fillRectangle(batx + 31, baty +3, 3, 6); //  BOBBL
              dc.drawRectangle(batx, baty, 31, 12); // Rahmen
              //Jetzt Füllstand zeichnen
               
               if (batt >= 50) { // großen Block zeichnen
                dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_GREEN);
                dc.fillRectangle(batx +1, baty+1, 14, 10);
                if (batt >= 60){dc.fillRectangle(batx+16, baty+1, 2, 10);}
                if (batt >= 70){dc.fillRectangle(batx+19, baty+1, 2, 10);}
                if (batt >= 80){dc.fillRectangle(batx+22, baty+1, 2, 10);}
                if (batt >= 90){dc.fillRectangle(batx+25, baty+1, 2, 10);}
                if (batt >= 100){dc.fillRectangle(batx+1, baty+1, 29, 10);
                   dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
                   dc.drawText(batx+3 ,  baty+4 , Gfx.FONT_XTINY, "100" , Gfx.TEXT_JUSTIFY_LEFT|Gfx.TEXT_JUSTIFY_VCENTER); 
                }
               }else { // kleiner 50% akku
                dc.setColor(Gfx.COLOR_DK_GREEN, Gfx.COLOR_DK_GREEN);
                if (batt >= 40){dc.fillRectangle(batx+12, baty+1, 4, 10);} 
                dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_YELLOW);
                if (batt >= 30){dc.fillRectangle(batx+8, baty+1, 4, 10);} 
                dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_ORANGE);
                if (batt >= 20){dc.fillRectangle(batx+5, baty+1, 4, 10);} 
                dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
                if (batt >= 11){dc.fillRectangle(batx+1, baty+1, 4, 10);} // 10% Rest
                else{
                 if (sec %2 == 1){   
                    dc.fillRectangle(batx+1, baty+1, 3, 10);
                 }else{
                   dc.drawText(batx+3 ,  baty+5 , Gfx.FONT_XTINY, "LOW" , Gfx.TEXT_JUSTIFY_LEFT|Gfx.TEXT_JUSTIFY_VCENTER);  
                 }
                }
                if (batt >=11) { // Batt Text ausgeben zwischen 49% und 11%
                    dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
                    dc.drawText(batx+15 ,  baty+5 , Gfx.FONT_XTINY, batt.toString() , Gfx.TEXT_JUSTIFY_LEFT|Gfx.TEXT_JUSTIFY_VCENTER);
                 } 
                } // Ende BATT
} // Ende drawbattfunction    

}
