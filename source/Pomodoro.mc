using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Attention as Attention;
using Toybox.Timer as Timer;
using Toybox.Lang as Lang;

// core Pomodoro functionality is a singleton, hence no class
module Pomodoro {
	var minuteTimer;
	var tickTimer;

	// pomodoro states: ready -> running -> break -> ready ...
	enum {
		stateReady,
		stateRunning,
		stateBreak
	}
	var currentState = stateReady;
	var pomodoroIteration = 1;
	var minutesLeft = 0;

	// cached app properties to reduce battery load
	var tickStrength;
	var tickDuration;

	// called when app is started for the first time
	function initialize() {	
		tickStrength = App.getApp().getProperty( "tickStrength" );
		tickDuration = App.getApp().getProperty( "tickDuration" );

		minuteTimer = new Timer.Timer();
		tickTimer = new Timer.Timer();
		
		resetAndStart();
	}

	function vibrate( dutyCycle, length ) {
		if ( Attention has :vibrate ) {
			Attention.vibrate([ new Attention.VibeProfile(
						dutyCycle, length ) ] );
		}
	}

	// if not muted
	function playAttentionTone( tone ) {
		var isMuted =  App.getApp().getProperty( "muteSounds" );
		if ( ! isMuted && Attention has :playTone ) {
			Attention.playTone( tone );
		}
	}

	function isInBreakState() {
		return currentState == stateBreak;
	}

	function isInRunningState() {
		return currentState == stateRunning;
	}

	function isInReadyState() {
		return currentState == stateReady;
	}

	function isLongBreak() {
		var groupLength = App.getApp().getProperty(
					"numberOfPomodorosBeforeLongBreak" );
		return ( pomodoroIteration % groupLength ) == 0;
	}

	function resetMinutesForBreak() {
		var breakVariant =  isLongBreak() ?
					"longBreakLength" :
					"shortBreakLength";
		minutesLeft = App.getApp().getProperty( breakVariant );
	}

	function resetMinutesForPomodoro() {
		minutesLeft = App.getApp().getProperty( "pomodoroLength" );
	}

	// for GarmodoroView
	function getMinutesLeft() {
		return minutesLeft.format( "%02d" );
	}

	// for GarmodoroView
	function getIteration() {
		return pomodoroIteration;
	}

	// called on initialization and by StopMenuDelegate 
	function resetAndStart() {
		playAttentionTone( 9 ); // Attention.TONE_RESET
		vibrate( 50, 1500 );

		pomodoroIteration = 1;
		currentState = stateReady;
		transitionToNextState();
	}

	// called every minute by minuteTimer
	function countdownMinutes() {
		minutesLeft -= 1;

		if ( minutesLeft <= 0 ) {
			if( isInRunningState() ) {
				playAttentionTone( 10 ); // Attention.TONE_LAP
				vibrate( 100, 1500 );
			} else if (isInBreakState()) {
				playAttentionTone( 7 ); // Attention.TONE_INTERVAL_ALERT
				vibrate( 100, 1500 );
			} else {
				// in ready state: nag every 5 minutes
				vibrate( 75, 1500 );
				minutesLeft = 5;
			}
		}

		Ui.requestUpdate();
	}

	function beginMinuteCountdown() {
		var countdown = new Lang.Method(Pomodoro, :countdownMinutes);
		minuteTimer.start( countdown, 60 * 1000, true );
	}

	// called every second by tickTimer, if ticking is enabled
	function makeTickingSound() {
		vibrate( tickStrength, tickDuration );
	}

	function shouldTick() {
		return App.getApp().getProperty( "tickStrength" ) > 0;
	}

	// one tick every second
	function beginTickingIfEnabled() {
		if ( shouldTick() ) {
			var makeTick = new Lang.Method(Pomodoro, :makeTickingSound);
			tickTimer.start( makeTick, 1000, true );
		}
	}

	function stopTimers() {
		tickTimer.stop();
		minuteTimer.stop();
	}

	// enter next pomodoro phase
	function transitionToNextState() {
		stopTimers();

		if( currentState == stateBreak ) {
			currentState = stateReady;
			pomodoroIteration += 1;
		} else if( currentState == stateReady ) {
			currentState = stateRunning;
			resetMinutesForPomodoro();
			beginTickingIfEnabled();
		} else { // currentState == stateRunning
			currentState = stateBreak;
			resetMinutesForBreak();
		}

		beginMinuteCountdown();
	}
}
