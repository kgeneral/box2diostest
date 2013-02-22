//
//  DYAppDelegate.h
//  Box2DTest
//
//  Created by Dae-Yeong Kim on 13. 2. 13..
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DYViewController.h"

@class DYViewController;

@interface DYAppDelegate : UIResponder <UIApplicationDelegate> {
    DYViewController* _glView;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) DYViewController *viewController;


@end
