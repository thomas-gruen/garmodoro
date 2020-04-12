using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Pomodoro;

class GarmodoroDelegate extends Ui.BehaviorDelegate {
	function initialize() {
		Ui.BehaviorDelegate.initialize();
	}

	function onBack() {
		if( Pomodoro.isInReadyState() ) {
			// exits application
			Ui.popView( Ui.SLIDE_RIGHT );
		} else {
			// asks again, prevents inadvertent exit
			onMenu();
		}
		return true;
	}

	function onSelect() {
		Pomodoro.transitionToNextState();
		Ui.requestUpdate();
		return true;
	}

	function onNextMode() {
		return true;
	}

	function onNextPage() {
		return true;
	}

	// also called from and onBack()
	function onMenu() {
		Ui.pushView( new Rez.Menus.StopMenu(),
					new StopMenuDelegate(), Ui.SLIDE_UP );
		return true;
	}
}
