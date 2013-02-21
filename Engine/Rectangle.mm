#include "Rectangle.h"

void Rectangle::_generateVerticesPosition() {
	// vertices on _radian = 0
	// clockwise from left-top
	float lefttop_x = -_width / 2;
	float lefttop_y = _height / 2;

	float righttop_x = _width / 2;
	float righttop_y = _height / 2;

	float rightbottom_x = _width / 2;
	float rightbottom_y = -_height / 2;

	float leftbottom_x = -_width / 2;
	float leftbottom_y = -_height / 2;

	// rotate matrix 2x2
	float _rotate[4];
	_rotate[0]=cos(_radian);
	_rotate[1]=-sin(_radian);

	_rotate[2]=sin(_radian);
	_rotate[3]=cos(_radian);

	_gRectangleVertices[0] = _rotate[0]*lefttop_x + _rotate[1]*lefttop_y;
	_gRectangleVertices[1] = _rotate[2]*lefttop_x + _rotate[3]*lefttop_y;

	_gRectangleVertices[2] = _rotate[0]*righttop_x + _rotate[1]*righttop_y;
	_gRectangleVertices[3] = _rotate[2]*righttop_x + _rotate[3]*righttop_y;

	_gRectangleVertices[4] = _rotate[0]*rightbottom_x + _rotate[1]*rightbottom_y;
	_gRectangleVertices[5] = _rotate[2]*rightbottom_x + _rotate[3]*rightbottom_y;

	_gRectangleVertices[6] = _rotate[0]*leftbottom_x + _rotate[1]*leftbottom_y;
	_gRectangleVertices[7] = _rotate[2]*leftbottom_x + _rotate[3]*leftbottom_y;


	_gRectangleVertices[0] += _position[0];
	_gRectangleVertices[1] += _position[1];

	_gRectangleVertices[2] += _position[0];
	_gRectangleVertices[3] += _position[1];

	_gRectangleVertices[4] += _position[0];
	_gRectangleVertices[5] += _position[1];

	_gRectangleVertices[6] += _position[0];
	_gRectangleVertices[7] += _position[1];
}
