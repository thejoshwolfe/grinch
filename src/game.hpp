#ifndef GAME_HPP
#define GAME_HPP

#include "list.hpp"
#include "entity.hpp"

extern List<Entity> entities;

void game_init();
void run_the_game();

#endif
