//
//  MyOpenGLESView.h
//  MyOpenGLES
//
//  Created by Archer_LJ on 14-5-9.
//  Copyright (c) 2014年 Archer_LJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/ES2/gl.h>
#define MAX_SIZE 1024

@interface MyOpenGLESView : UIView
{
    CAEAGLLayer* layer;
}

@property (nonatomic, retain) EAGLContext* context;
@property (nonatomic, assign) GLuint colorRenderBuffer;
@property (nonatomic, assign) GLuint depthRenderBuffer;
@property (nonatomic, assign) GLuint frameBuffer;

@property (nonatomic, assign) int viewWidth;
@property (nonatomic, assign) int viewHeight;

@property (nonatomic, assign) int redSize;
@property (nonatomic, assign) int greenSize;
@property (nonatomic, assign) int blueSize;
@property (nonatomic, assign) int alphaSize;
@property (nonatomic, assign) int depthSize;
@property (nonatomic, assign) int stencilSize;
@property (nonatomic, assign) int samplesSize;

//-(void)CADisplayLinkRender:(CADisplayLink*)displayLink;

-(BOOL)Init;
-(BOOL)Render;
-(void)Finish;

-(void)SwapBuffers;

// True init function
-(BOOL)Initialize:(int)redsize GreenSize:(int)greensize BlueSize:(int)bluesize AlphaSize:(int)alphasize DepthSize:(int)depthsize StencilSize:(int)stencilsize SamplesSize:(int)samplessize;

-(void)SetupLayer;
-(void)SetupContext;
-(void)SetupRenderBuffer;
-(void)SetupDepthBuffer;
-(void)SetupFrameBuffer;

-(void)DestroyBuffers;

-(BOOL)CompileShader:(char*)shadersource shader:(GLuint)shader;
-(BOOL)LoadShaders:(char*)vssource fragsource:(char*)fssource program:(GLuint*)prog;

@end
