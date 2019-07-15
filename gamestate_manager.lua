local gamestate_manager = {states = {
	Splash = require "gamestates/SplashState",
	Play = require "gamestates/PlayState",
	GameOver = require "gamestates/GameOverState",
}}

function gamestate_manager.switch_to(new_state)
	if gamestate.exit then
		gamestate:exit()
	end
	gamestate = gamestate_manager.states[new_state]:new()
	if gamestate.enter then
		gamestate:enter()
	end
end

return gamestate_manager
