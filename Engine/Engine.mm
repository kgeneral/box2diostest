#include "Engine.h"

// constructor, destructor
Engine::Engine() {
	b2Vec2 gravity(0.0f, -10.0f);
	_world = new b2World(gravity);
}
Engine::~Engine() {
	delete _world;
}

//private
void Engine::_addBox(Rectangle* rect){

	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
	float* pos = rect->getPosition();
	bodyDef.position.Set(pos[0], pos[1]);
	b2Body* newBody = _world->CreateBody(&bodyDef);

    newBody->ApplyForce(*(new b2Vec2(0, -1000)), newBody->GetWorldCenter());

	//LOGI("# of bodies : %d", _world->GetBodyCount());

	b2PolygonShape dynamicBox;
	dynamicBox.SetAsBox(rect->getWidth() / 2, rect->getHeight() / 2);

	b2FixtureDef fixtureDef;
	fixtureDef.shape = &dynamicBox;
	fixtureDef.restitution = 0.2f;
	fixtureDef.density = 1.0f;
	fixtureDef.friction = 0.3f;

	newBody->CreateFixture(&fixtureDef);

	rect->setBody(newBody);
}

void Engine::_deleteBox(Rectangle* rect){
	b2Body* body = rect->getBody();
	_world->DestroyBody(body);
}

//public
Rectangle* Engine::addGround(float x, float y, float width, float height) {
	b2BodyDef groundBodyDef;
	groundBodyDef.position.Set(x, y);
	b2Body* groundBody = _world->CreateBody(&groundBodyDef);

	b2PolygonShape groundBox;
	groundBox.SetAsBox(width, height);
	groundBody->CreateFixture(&groundBox, 0.0f);

	Rectangle* groundRect = new Rectangle();
	groundRect->setPosition(x, y);
	groundRect->setSize(width, height);
	groundRect->setBody(groundBody);

	return groundRect;
	//groundList.push_front(groundRect);
}

Rectangle* Engine::addBox(float x, float y, float width, float height) {
	//LOGI("addBox(%f, %f)", x, y);

	Rectangle* newRect = new Rectangle();
	newRect->setPosition(x, y);
	newRect->setSize(width, height);

	_addQueue.push(newRect);
	return newRect;
}

bool Engine::destroyBox(Rectangle* box) {
	//LOGI("destroyBox(%x)", box);
	_deleteQueue.push(box);
	return true;
}

void Engine::runStep() {
	// lock while time step
	// if not locked, add items from queue;
	if(!_world->IsLocked()) {
		Rectangle* rect;
		// add from queue
		while (!_addQueue.empty()) {
			rect = _addQueue.front();
			_addBox(rect);
			_addQueue.pop();
		}
		//destroy from queue
		while (!_deleteQueue.empty()) {
			rect = _deleteQueue.front();
			_deleteBox(rect);
			_deleteQueue.pop();
		}
	}

	// 2.4 Simulating the _World (of Box2D)
	float32 timeStep = 1.0f / 60.0f;
	int32 velocityIterations = 6;
	int32 positionIterations = 2;
	_world->Step(timeStep, velocityIterations, positionIterations);
}
