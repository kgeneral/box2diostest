#ifndef BOX2D
#define BOX2D
#include <Box2D/Box2D.h>
#endif

#ifndef RENDER
#define RENDER
#include "Rectangle.h"
#endif

#include <queue>

class Engine {
private:
    b2World* _world;

	std::queue<Rectangle*> _addQueue;
	std::queue<Rectangle*> _deleteQueue;

	void _addBox(Rectangle* rect);
	void _deleteBox(Rectangle* rect);

public:
	Engine();
	~Engine();

	Rectangle* addGround(float x, float y, float width, float height);
	Rectangle* addBox(float x, float y, float width, float height);
	bool destroyBox(Rectangle* box);
	void runStep();
};
