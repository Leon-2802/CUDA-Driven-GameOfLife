#include "game_window.h"

int main() {
	GameWindow window(800, 600, false);
	bool running = true;

	// call cuda init function

	while (running) {
		window.run();
		running = window.processEvents();
	}

    return 0;
}