//
//  Texture.h
//  Box2DTest
//
//  Created by Dae-Yeong Kim on 13. 2. 21..
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

class Texture {
private:
    void* _imageData;
    int _width;
    int _height;
    
public:
    Texture(void* imageData, int width, int height){
        _imageData = imageData;
        _width=width;
        _height=height;
        
    }
    ~Texture(){
        delete _imageData;
    }
    
    void* getImageData(){
        return _imageData;
    }
    int getWidth() {
        return _width;
    }
    int getHeight() {
        return _height;
    }
    
};
