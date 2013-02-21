#ifndef BOX2D
#define BOX2D
#include <Box2D/Box2D.h>
#endif

class Rectangle {
private:
    float _gRectangleVertices[8];
    float _position[2];
    float _width, _height;
    float _radian;

    b2Body* _body;

    bool _isSimulating;

    void _generateVerticesPosition();

public:
    Rectangle(){
        //_gRectangleVertices = new float(8);
        _position[0]=0;_position[1]=0;
        _width=1;_height=1;
        _radian=0;
        _generateVerticesPosition();
        _isSimulating = false;
    }
    ~Rectangle(){
        //delete _gRectangleVertices;
    }
    b2Body* getBody() {
        return _body;
    }
    bool isSimulating(){
    	return _isSimulating;
    }
    void setBody(b2Body* body) {
    	_isSimulating = true;
        _body=body;
    }
    float* getPosition() {
    	return _position;
    }
    float getWidth(){
        return _width;
    }
    float getHeight(){
        return _height;
    }
    void setPosition(float x, float y) {
        _position[0]=x;_position[1]=y;
        //_generateVerticesPosition();
    }
    void setSize(float half_width, float half_height){
        _width=half_width*2;_height=half_height*2;
        //_generateVerticesPosition();
    }
    void setRadian(float radian){
        _radian=radian;
        //_generateVerticesPosition();
    }
    float* getRectangleVertices() {
        _generateVerticesPosition();
        return _gRectangleVertices;
    }
};
