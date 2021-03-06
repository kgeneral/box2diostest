//
//  DYViewController.m
//  Box2DTest
//
//  Created by Dae-Yeong Kim on 13. 2. 13..
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "DYViewController.h"
#import "Engine.h"
//#include <Box2D/Box2D.h>

//stl box list
#import <list>

#include <ft2build.h>
#include FT_FREETYPE_H

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

Engine* engine;

std::list<Rectangle*> groundList;
std::list<Rectangle*> boxList;

double pastms = [[NSDate date] timeIntervalSince1970];
double generateInterval = 0.0f;

@interface DYViewController () {
    
    CAEAGLLayer* _eaglLayer;
    EAGLContext* _context;
    GLuint _colorRenderBuffer;
    GLuint _positionSlot;
    GLuint _colorSlot;
    GLuint _projectionUniform;
    GLuint _modelViewUniform;
    float _currentRotation;
    GLuint _depthRenderBuffer;
    
    
    GLuint _program;
    
    //GLKMatrix4 _modelViewProjectionMatrix;
    //GLKMatrix3 _normalMatrix;
    float _rotation;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    
    GLuint gvPositionHandle;
    GLuint gvTextureHandle;
    GLuint gvSamplerHandle;
    
    GLuint boxTextureId;
    GLuint groundTextureId;
    GLuint skyTextureId;
    
//    GLuint textBitmapTextureId;
}
@property (strong, nonatomic) EAGLContext *context;
@property (nonatomic, strong) UILabel *debug;
//@property (strong, nonatomic) GLKBaseEffect *effect;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation DYViewController

@synthesize debug;
@synthesize context = _context;
//@synthesize effect = _effect;

- (void)_debug_data:(float)fps box_num:(int)box_num {
    self.debug.text = [NSString stringWithFormat:@"fps : %f, box : %d", fps, box_num];
}
- (void)_debug_message:(NSString *)message {
    self.debug.text = @"test";
}

- (void)setupLayer {
    _eaglLayer = (CAEAGLLayer*) self.view.layer;
    _eaglLayer.opaque = YES;
}
- (void)setupContext {   
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}
- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);        
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];    
}

- (void)setupDepthBuffer {
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.view.frame.size.width, self.view.frame.size.height);    
}
- (void)setupFrameBuffer {    
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);   
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
}

- (void)setupVBOs {
 /*   
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_vertexBuffer2);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer2);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices2), Vertices2, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer2);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer2);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices2), Indices2, GL_STATIC_DRAW);
   */ 
}
- (void)setupDisplayLink {
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];    
}
- (void)makeBox:(float)x y:(float)y {
    
    boxList.push_front(engine->addBox(x, y, 0.5f, 0.5f));
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // add debug label
    CGRect sumFrame = CGRectMake(50, 50, 300, 30);
    self.debug = [[UILabel alloc] initWithFrame:sumFrame];
    self.debug.text = @"debug";
    self.debug.font = [UIFont boldSystemFontOfSize:15];
    self.debug.textAlignment = UITextAlignmentLeft;
    self.debug.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.debug];
    
    pastms = [[NSDate date] timeIntervalSince1970];
    //setup engine
    engine = new Engine();
    
    groundList.push_front(engine->addGround(0.0f, -16.0f, 50.0f, 10.0f));
    
    groundList.push_front(engine->addGround(-2.0f, 2.0f, 1.0f, 0.2f));
    groundList.push_front(engine->addGround(5.0f, 2.0f, 1.0f, 0.2f));
    groundList.push_front(engine->addGround(4.0f, -1.0f, 1.0f, 0.2f));
    
    //        [self setupGL];
    [self setupLayer];
    [self setupContext];
    [self setupDepthBuffer];
    [self setupRenderBuffer];        
    [self setupFrameBuffer];
    [self loadShaders];
    //[self compileShaders];
    //[self setupVBOs];
    [self setupDisplayLink];
    
    boxTextureId = [self CreateTexture2D:@"box1.png"];
    skyTextureId = [self CreateTexture2D:@"sky.png"];
}

- (void)viewDidUnload
{    
    [super viewDidUnload];
    
    // clean maked box
    Rectangle* rect;
    while (!groundList.empty()) {
        rect = groundList.front();
        delete rect;
        groundList.pop_front();
    }
    while (!boxList.empty()) {
        rect = boxList.front();
        delete rect;
        boxList.pop_front();
    }
    delete engine;
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
	self.context = nil;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}
//http://developer.apple.com/library/ios/#documentation/3DDrawing/Conceptual/OpenGLES_ProgrammingGuide/TechniquesforWorkingwithVertexData/TechniquesforWorkingwithVertexData.html
- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    
    //self.effect = [[GLKBaseEffect alloc] init];
    //self.effect.light0.enabled = GL_TRUE;
    //self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    

    
    //glViewport(0, 0, w, h);
    //glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);
    /*
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));

    glBindVertexArrayOES(0);
         */
}

-(GLuint) CreateTexture2D:(NSString *) fileName {
    
    // Texture object handle
    GLuint textureId;
    
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    GLubyte *spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, 
                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);    
    
    // 3
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    NSLog(@"width %lu height %lu", width, height);
    
    // Use tightly packed data
    glPixelStorei ( GL_UNPACK_ALIGNMENT, 1 );
    
    // Generate a texture object
    glGenTextures ( 1, &textureId );
    
    // Bind the texture object
    glBindTexture ( GL_TEXTURE_2D, textureId );
    
    // Set the filtering mode
    glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
    //glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
    
    // Load the texture
    glTexImage2D ( GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    
    return textureId;
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    //glDeleteVertexArraysOES(1, &_vertexArray);
    
    //self.effect = nil;
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

-(void) drawSky {
    GLfloat vertices[] = { -10.0f,  -10.0f,        // vertices 0 
        -10.0f,  30.0f,        // vertices 1
        10.0f,  30.0f,        // vertices 2
        10.0f,  -10.0f         // vertices 3
    };
    glVertexAttribPointer(gvPositionHandle, 2, GL_FLOAT, GL_FALSE, 0, vertices);
    GLfloat texVertices[] = { 0.0f,  0.0f,        // TexCoord 0 
        0.0f,  1.0f,        // TexCoord 1
        1.0f,  1.0f,        // TexCoord 2
        1.0f,  0.0f         // TexCoord 3
    };
    // Load the texture coordinate
    glVertexAttribPointer(gvTextureHandle, 2, GL_FLOAT,
                          GL_FALSE, 0, texVertices );
    
    glEnableVertexAttribArray(gvPositionHandle);   
    glEnableVertexAttribArray(gvTextureHandle);
    
    // Bind the texture
    glActiveTexture ( GL_TEXTURE0 );
    glBindTexture ( GL_TEXTURE_2D, skyTextureId );
    
    // Set the filtering mode
    glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
    glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
    glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
    glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
    
    // Set the sampler texture unit to 0
    glUniform1i ( gvSamplerHandle, 0 );
    
    GLushort indices[] = { 0, 1, 2, 0, 2, 3 };
    glDrawElements ( GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, indices );        
    
}
-(void) drawGround:(GLfloat *)vertices {
    glVertexAttribPointer(gvPositionHandle, 2, GL_FLOAT, GL_FALSE, 0, vertices);
    GLfloat texVertices[] = { 0.0f,  0.0f,        // TexCoord 0 
        0.0f,  3.0f,        // TexCoord 1
        1.0f,  3.0f,        // TexCoord 2
        1.0f,  0.0f         // TexCoord 3
    };
    // Load the texture coordinate
    glVertexAttribPointer(gvTextureHandle, 2, GL_FLOAT,
                          GL_FALSE, 0, texVertices );
    
    glEnableVertexAttribArray(gvPositionHandle);   
    glEnableVertexAttribArray(gvTextureHandle);
    
    // Bind the texture
    glActiveTexture ( GL_TEXTURE0 );
    glBindTexture ( GL_TEXTURE_2D, boxTextureId );
    
    // Set the filtering mode
    glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
    glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
    glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
    glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
    
    // Set the sampler texture unit to 0
    glUniform1i ( gvSamplerHandle, 0 );
    
    GLushort indices[] = { 0, 1, 2, 0, 2, 3 };
    glDrawElements ( GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, indices );        
    
}
-(void) drawBox:(GLfloat *)vertices {
    glVertexAttribPointer(gvPositionHandle, 2, GL_FLOAT, GL_FALSE, 0, vertices);
    GLfloat texVertices[] = { 0.0f,  0.0f,        // TexCoord 0 
        0.0f,  1.0f,        // TexCoord 1
        1.0f,  1.0f,        // TexCoord 2
        1.0f,  0.0f         // TexCoord 3
    };
    // Load the texture coordinate
    glVertexAttribPointer(gvTextureHandle, 2, GL_FLOAT,
                          GL_FALSE, 0, texVertices );
    
    glEnableVertexAttribArray(gvPositionHandle);   
    glEnableVertexAttribArray(gvTextureHandle);
    
    // Bind the texture
    glActiveTexture ( GL_TEXTURE0 );
    glBindTexture ( GL_TEXTURE_2D, boxTextureId );
    
    // Set the filtering mode
    glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
    glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
    
    // Set the sampler texture unit to 0
    glUniform1i ( gvSamplerHandle, 0 );
    
    GLushort indices[] = { 0, 1, 2, 0, 2, 3 };
    glDrawElements ( GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, indices );        
    
}

-(void) drawText:(float) fps{
     /*
    
    
    //render
    
    GLfloat vertices[] = { -10.0f,  -6.0f,        // vertices 0 
        -10.0f,  -4.0f,        // vertices 1
        10.0f,  -4.0f,        // vertices 2
        10.0f,  -6.0f         // vertices 3
    };
    glVertexAttribPointer(gvPositionHandle, 2, GL_FLOAT, GL_FALSE, 0, vertices);
    GLfloat texVertices[] = { 0.0f,  0.0f,        // TexCoord 0 
        0.0f,  1.0f,        // TexCoord 1
        1.0f,  1.0f,        // TexCoord 2
        1.0f,  0.0f         // TexCoord 3
    };
    // Load the texture coordinate
    glVertexAttribPointer(gvTextureHandle, 2, GL_FLOAT,
                          GL_FALSE, 0, texVertices );
    
    glEnableVertexAttribArray(gvPositionHandle);   
    glEnableVertexAttribArray(gvTextureHandle);
    
    

    // Bind the texture
    glActiveTexture ( GL_TEXTURE0 );
    glBindTexture ( GL_TEXTURE_2D, textBitmapTextureId );
    
    // Set the filtering mode
    //glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
    //glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
    //glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
    //glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
    
    // Set the sampler texture unit to 0
    glUniform1i ( gvSamplerHandle, 0 );
    
    GLushort indices[] = { 0, 1, 2, 0, 2, 3 };
    glDrawElements ( GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, indices );   
      */
    
}

/*
 
 // Texture object handle
 GLuint textureId;
 
 CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
 if (!spriteImage) {
 NSLog(@"Failed to load image %@", fileName);
 exit(1);
 }
 
 size_t width = CGImageGetWidth(spriteImage);
 size_t height = CGImageGetHeight(spriteImage);
 GLubyte *spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
 
 CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, 
 CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);    
 
 // 3
 CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
 
 CGContextRelease(spriteContext);
 
 NSLog(@"width %lu height %lu", width, height);
 
 // Use tightly packed data
 glPixelStorei ( GL_UNPACK_ALIGNMENT, 1 );
 
 // Generate a texture object
 glGenTextures ( 1, &textureId );
 
 // Bind the texture object
 glBindTexture ( GL_TEXTURE_2D, textureId );
 
 // Set the filtering mode
 glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
 //glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
 
 // Load the texture
 glTexImage2D ( GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
 
 free(spriteData);
 
 return textureId;
 
 
 http://developer.apple.com/library/ios/#documentation/uikit/reference/NSString_UIKit_Additions/Reference/Reference.html
 UIStringDrawing
 
 
 if (_contextBuffer == NULL) {
 _contextBuffer = calloc(height, width);
 }
 CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
 _context = CGBitmapContextCreate(_contextBuffer, width, height, 8, width, colorSpace, kCGImageAlphaOnly);
 CGColorSpaceRelease(colorSpace);
 
 
 //
 
 
 UIGraphicsPushContext(_context);
 
 NSString* platformText = @"test";
 UITextAlignment platformAlignment = textAlignmentPlatform(_textAlignment);
 UILineBreakMode platformLineBreakMode = textLineBreakModePlatform(_textLineBreakMode);
 
 CGRect r = CGRectMake(0, 0, _width, _height);
 
 Size2D textSize = sizeMt([platformText drawInRect:r withFont:font lineBreakMode:platformLineBreakMode alignment:platformAlignment]);
 
 // there's a bug if texts are single line
 tstring tstr = tstring(_text->getCStr());
 size_t newLinePos = tstr.find(_T("\n"));
 bool singleLine = newLinePos == tstring::npos;
 if (singleLine) {
 textSize = Size2D(textSize.getW(), textSize.getH() - 2.0f);
 }
 
 UIGraphicsPopContext();
 
 
 // 이렇게 하시고 나면 _contextBuffer 에 이미지 데이터가 들어갑니다. 
 
 //NSString text 
 
 size_t width = 100;
 size_t height = 100;
 GLubyte *_textContextBuffer;
 
 if (_textContextBuffer == NULL) {
 _textContextBuffer = (GLubyte *)calloc(height, width);
 }
 CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
 CGContextRef textSpriteContext = CGBitmapContextCreate(_textContextBuffer, width, height, 8, width, colorSpace, kCGImageAlphaOnly);
 CGColorSpaceRelease(colorSpace);
 
 //    NSLog(@"fps = %f", 1 / intervalms);
 
 UIGraphicsPushContext(UIGraphicsGetCurrentContext());
 
 NSString* platformText = @"test";
 //UITextAlignment platformAlignment = textAlignmentPlatform(_textAlignment);
 //UILineBreakMode platformLineBreakMode = textLineBreakModePlatform(_textLineBreakMode);
 
 CGRect r = CGRectMake(0, 0, width, height);
 
 //Size2D textSize = sizeMt([platformText drawInRect:r withFont:font lineBreakMode:nil alignment:nil]);
 
 // there's a bug if texts are single line
 
 tstring tstr = tstring(_text->getCStr());
 size_t newLinePos = tstr.find(_T("\n"));
 bool singleLine = newLinePos == tstring::npos;
 if (singleLine) {
 textSize = Size2D(textSize.getW(), textSize.getH() - 2.0f);
 }
 
 UIGraphicsPopContext();
 
 
 UIFont *font = [UIFont systemFontOfSize:16.0];
 [platformText drawAtPoint:CGPointMake(0, 0) withFont:font];
 
 
 
 
 // _textContextBuffer 에 이미지 데이터가 들어감
 

 */


- (void)render:(CADisplayLink*)displayLink {
    
    //print fps
    double curms = [[NSDate date] timeIntervalSince1970];
    double intervalms = curms - pastms;
    //NSLog(@"fps = %f", 1 / intervalms);
    pastms = curms;
    
    //check interval
    generateInterval += intervalms;
    if(generateInterval > 0.05f) {
        int a = arc4random() % 1000;
        float x = (float)(a - 500.0f) / 100.0f;
        [self _debug_data:(1 / intervalms) box_num:boxList.size()];
        //NSLog(@"total : %lu, new box = %f %f",boxList.size(), x, 50.0f);
        [self makeBox:x y:50.0f];
        generateInterval = 0.0f;
        NSLog(@"fps = %f", 1 / intervalms);
    }
    

    
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);       
    
    //glUseProgram(_program);
    glViewport(0, 0, self.view.frame.size.width, self.view.frame.size.height);    
    
    engine->runStep();
    
    //ground
    for (std::list<Rectangle*>::iterator it=groundList.begin(); it!=groundList.end(); ++it) {
        
        b2Body* it_body = (*it)->getBody();
        
        b2Vec2 position = it_body->GetPosition();
        float32 angle = it_body->GetAngle();
        
        (*it)->setPosition(position.x, position.y);
        (*it)->setRadian(angle);
        
        GLfloat* vertices = (*it)->getRectangleVertices();
        [self drawGround:vertices];
    }
    
    //box
    for (std::list<Rectangle*>::iterator it=boxList.begin(); it!=boxList.end(); ++it) {
        
        if(!(*it)->isSimulating()) continue;
        
        b2Body* it_body = (*it)->getBody();
        
        b2Vec2 position = it_body->GetPosition();
        float32 angle = it_body->GetAngle();
        
        (*it)->setPosition(position.x, position.y);
        (*it)->setRadian(angle);
        
        GLfloat* vertices = (*it)->getRectangleVertices();  
        [self drawBox:vertices];
    }
    
    
    //[self drawText:(1 / intervalms)];
    [self drawSky];
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}
#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    //glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    //glBindAttribLocation(_program, ATTRIB_NORMAL, "normal");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    glUseProgram(_program);
    
    gvPositionHandle = glGetAttribLocation(_program, "vPosition");
    gvTextureHandle = glGetAttribLocation(_program, "a_TexCoordinate");
    gvSamplerHandle = glGetAttribLocation(_program, "u_Texture");
    
    
    
    // Get uniform locations.
    //uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    //uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@end
