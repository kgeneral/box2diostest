//
//  DYViewController.h
//  Box2DTest
//
//  Created by Dae-Yeong Kim on 13. 2. 13..
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

@interface DYViewController : UIViewController
-(GLuint) CreateTexture2D:(NSString *) fileName;
@end
