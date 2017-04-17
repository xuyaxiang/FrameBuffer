#import "MyOpenGLESView.h"
#import "gmVector.h"
#import "gmMatrix.h"

@implementation MyOpenGLESView

@synthesize context = _context;
@synthesize colorRenderBuffer = _colorRenderBuffer;
@synthesize depthRenderBuffer = _depthRenderBuffer;
@synthesize frameBuffer = _frameBuffer;

@synthesize viewWidth = _viewWidth;
@synthesize viewHeight = _viewHeight;

@synthesize redSize = _redSize;
@synthesize greenSize = _greenSize;
@synthesize blueSize = _blueSize;
@synthesize alphaSize = _alphaSize;
@synthesize depthSize = _depthSize;
@synthesize stencilSize = _stencilSize;
@synthesize samplesSize = _samplesSize;


char* vssource =
"precision mediump float;\n"
"attribute vec4 aPosition;\n"
"attribute vec2 aTexCoord;\n"
"uniform mat4 uMvp;\n"
"varying vec2 vTexCoord;\n"
"void main() {\n"
"    gl_Position = uMvp*aPosition;\n"
"    vTexCoord = aTexCoord;\n"
"}\n";

char* fssource =
"precision mediump float;\n"
"uniform sampler2D uTex;\n"
"varying vec2 vTexCoord;\n"
"void main() {\n"
"    gl_FragColor = texture2D(uTex, vTexCoord);\n"
"}\n";

GLuint program;
GLint aLocPos,aLocTexCoord;
GLint uLocMvp,uLocTex;
gmMatrix4 mvp;
#define VERTEX 0
#define INDEX 1
GLuint cube_buffers[2] = {0};
GLuint quad_buffers[2] = {0};
GLuint tex;
GLuint fbo,fbo_tex;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(BOOL)Initialize:(int)redsize GreenSize:(int)greensize BlueSize:(int)bluesize AlphaSize:(int)alphasize DepthSize:(int)depthsize StencilSize:(int)stencilsize SamplesSize:(int)samplessize{
    _redSize = redsize;
    _greenSize = greensize;
    _blueSize = bluesize;
    _alphaSize = alphasize;
    _depthSize = depthsize;
    _stencilSize = stencilsize;
    _samplesSize = samplessize;
    [self SetupLayer];//初始化EAGLlayer
    [self SetupContext];//初始化绘图上下文
    [self SetupRenderBuffer];//初始化颜色缓冲区,将该缓冲区与layer绑定，随后可以调用present方法显示
    if (_depthSize > 0) {
        [self SetupDepthBuffer];//为深度缓冲区分配空间
    }
    [self SetupFrameBuffer];//配置一个帧缓存,该帧缓存有一个颜色附着点，深度附着点
    if ([self Init]) {
        CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(CADisplayLinkRender:)];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        return YES;
    }
    return NO;
}

+(Class)layerClass{
    return [CAEAGLLayer class];
}

-(void)SetupLayer{
    layer = (CAEAGLLayer *)self.layer;
    layer.opaque = NO;
//    NSString *colorFormat = @"";
//    if(_redSize == 5 && _greenSize == 6 && _blueSize == 5)
//    {
//        colorFormat = kEAGLColorFormatRGB565;
//    }
//    else if(_redSize == 8 && _greenSize == 8 && _blueSize == 8)
//    {
//        colorFormat = kEAGLColorFormatRGBA8;
//    }
//    else
//    {
//        NSLog(@"connot support this format, failed");
//        exit(-1);
//    }
//    layer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];
    
}

-(void)SetupContext{
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc]initWithAPI:api];
    if (!_context) {
        NSLog(@"Create EGL Context Failed");
        exit(-1);
    }
    if(![EAGLContext setCurrentContext:_context])
    {
        NSLog(@"Set Current Context Failed");
        exit(-1);
    }
}

-(void)SetupRenderBuffer{
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
//    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA, self.frame.size.width, self.frame.size.height);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_viewWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_viewHeight);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
}

-(void)SetupDepthBuffer{
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    GLuint size = 0;
    
    if(_depthSize == 16)
    {
        size = GL_DEPTH_COMPONENT16;
    }
    else if(_depthSize == 24)
    {
        size = GL_DEPTH_COMPONENT24_OES;
    }
    else if(_depthSize == 32)
    {
        size = GL_DEPTH_COMPONENT32_OES;
    }
    else
    {
        NSLog(@"Invalide depth size");
    }
    if (size != 0) {
        glRenderbufferStorage(GL_RENDERBUFFER, size, _viewWidth, _viewHeight);
    }
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
}

-(void)SetupFrameBuffer{
    //framebuffer与一个颜色缓冲区以及一个深度缓冲区绑定在一起
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    if (_colorRenderBuffer) {
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    }
    if (_depthRenderBuffer) {
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
    }
}

-(void)DestroyBuffers
{
    if(_colorRenderBuffer)
    {
        glDeleteRenderbuffers(1, &_colorRenderBuffer);
        _colorRenderBuffer = 0;
    }
    
    if(_depthRenderBuffer)
    {
        glDeleteRenderbuffers(1, &_depthRenderBuffer);
        _depthRenderBuffer = 0;
    }
    
    if(_frameBuffer)
    {
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
}

-(void)CADisplayLinkRender:(CADisplayLink *)displayLink
{
    [self Render];
}

-(BOOL)Init{
    if (![self LoadShaders:vssource fragsource:fssource program:&program]) {
        return NO;
    }//加载shader，准备绘图
    glUseProgram(program);
    aLocPos = glGetAttribLocation(program, "aPosition");
    glEnableVertexAttribArray(aLocPos);
    
    aLocTexCoord = glGetAttribLocation(program, "aTexCoord");
    glEnableVertexAttribArray(aLocTexCoord);
    
    uLocMvp = glGetUniformLocation(program, "uMvp");
    uLocTex = glGetUniformLocation(program, "uTex");
    
    /* Init Matrix */
    InitgmMatrix4(&mvp);//获取相关变量的位置
    glGenBuffers(2, quad_buffers);
    glBindBuffer(GL_ARRAY_BUFFER, quad_buffers[VERTEX]);
    float plane[] =
    {
        -0.5f,      -0.5f,      -0.5f,      1.0f,   0.0f, 0.0f,
        0.5f,       -0.5f,      -0.5f,      1.0f,   1.0f, 0.0f,
        -0.5f,      0.5f,       -0.5f,      1.0f,   0.0f, 1.0f,
        0.5f,       0.5f,       -0.5f,      1.0f,   1.0f, 1.0f,
    };
    glBufferData(GL_ARRAY_BUFFER, sizeof(plane), plane, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, quad_buffers[INDEX]);
    
    static unsigned short plane_index[] =
    {
        /* 0 */
        0, 1, 2, 1, 2, 3,
    };//
    
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(plane_index), plane_index, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    
    glGenBuffers(2, cube_buffers);
    glBindBuffer(GL_ARRAY_BUFFER, cube_buffers[VERTEX]);
    float cube[] =
    {
        -0.5f,      -0.5f,      -0.5f,      1.0f,   0.0f, 0.0f,
        0.5f,       -0.5f,      -0.5f,      1.0f,   1.0f, 0.0f,
        -0.5f,      0.5f,       -0.5f,      1.0f,   0.0f, 1.0f,
        0.5f,       0.5f,       -0.5f,      1.0f,   1.0f, 1.0f,
        
        -0.5f,      -0.5f,      0.5f,       1.0f,   0.0f, 0.0f,
        0.5f,       -0.5f,      0.5f,       1.0f,   1.0f, 0.0f,
        -0.5f,      0.5f,       0.5f,       1.0f,   0.0f, 1.0f,
        0.5f,       0.5f,       0.5f,       1.0f,   1.0f, 1.0f,
    };
    glBufferData(GL_ARRAY_BUFFER, sizeof(cube), cube, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, cube_buffers[INDEX]);
    unsigned short cube_index[] =
    {
        0, 1, 2, 1, 2, 3,
        0, 4, 2, 6, 4, 2,
        0, 1, 4, 1, 5, 4,
        1, 3, 5, 3, 5, 7,
        2, 3, 6, 3, 6, 7,
        4, 5, 6, 5, 6, 7,
    };
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(cube_index), cube_index, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    //以上代码生成了一个方框以及一个cube
    
    //将会渲染到该纹理?
    glGenTextures(1, &fbo_tex);
    glBindTexture(GL_TEXTURE_2D, fbo_tex);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 256, 256, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glBindTexture(GL_TEXTURE_2D, 0);
    //将会渲染到上述纹理?
    
    glGenFramebuffers(1, &fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, fbo_tex, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    //这个fbo专门用于渲染到纹理
    
    //生成一个纹理,里面已经有了数据
    UIImage *img = [UIImage imageNamed:@"wood.png"];
    CFDataRef rawdata = CGDataProviderCopyData(CGImageGetDataProvider(img.CGImage));
    GLuint *pixels = (GLuint *)CFDataGetBytePtr(rawdata);
    int width = img.size.width;
    int height = img.size.height;
    if (pixels==NULL) {
        return NO;
    }
    glGenTextures(1, &tex);
    glBindTexture(GL_TEXTURE_2D, tex);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glBindTexture(GL_TEXTURE_2D, 0);
    return YES;
}

-(BOOL)Render{
    glEnable(GL_DEPTH_TEST);
//    glDepthFunc(GL_LESS);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    glClearColor(0, 0, 0, 1);
//    glClearDepthf(1.0);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    glViewport(0, 0, 256, 256);
    glUseProgram(program);
    glBindBuffer(GL_ARRAY_BUFFER, cube_buffers[VERTEX]);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, cube_buffers[INDEX]);
    gmMatrix4 view, proj;
    
    gmVector3 eye = {1.0f, 1.0f, -1.0f};
    gmVector3 at = {0.0f, 0.0f, 0.0f};
    gmVector3 up = {0.0f, 1.0f, 0.0f};
    
    gmMatrixLookAtLH(&view, &eye, &at, &up);
    
    gmMatrixPerspectiveFovLH(&proj, 3.1415f / 2, (float)_viewWidth / (float)_viewHeight, 1.0f, 1000.0f);
    
    gmMatrixMultiply(&mvp, &view, &proj);
    
    glUniformMatrix4fv(uLocMvp, 1, 0, (float*)&mvp);
    glVertexAttribPointer(aLocPos, 4, GL_FLOAT, 0, sizeof(float) * 6, 0);
    glVertexAttribPointer(aLocTexCoord, 2, GL_FLOAT, 0, sizeof(float)*6, (GLvoid*)(sizeof(float)*4));
    glBindTexture(GL_TEXTURE_2D, tex);
    glActiveTexture(GL_TEXTURE0);
    glUniform1i(uLocTex, 0);
    
    glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_SHORT, 0);//渲染完成一个场景，同时将tex的纹理渲染到fbo_tex中
    glBindFramebuffer(GL_FRAMEBUFFER, 0);//取消当前绑定的帧缓存
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);//绑定要绘制到前台的帧缓存
    glClearColor(0.5, 0, 0, 1.0);
//    glClearDepthf(1.0f);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    glViewport(0, 0, _viewWidth, _viewHeight);
    glUseProgram(program);
    glBindBuffer(GL_ARRAY_BUFFER, quad_buffers[VERTEX]);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, quad_buffers[INDEX]);
    InitgmMatrix4(&mvp);
    glUniformMatrix4fv(uLocMvp, 1, 0, (float *)&mvp);
    glVertexAttribPointer(aLocPos, 4, GL_FLOAT, 0, sizeof(float)*6, 0);
    glBindTexture(GL_TEXTURE_2D, fbo_tex);
    glActiveTexture(GL_TEXTURE0);
    glUniform1i(uLocTex, 0);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0);//将之前得到的fbo_tex贴到当前绘制的四边形上
    [self SwapBuffers];//交换当前帧，绘制到后帧缓存中
    return YES;
}

-(void)SwapBuffers{
    if (_context) {
        glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
        [_context presentRenderbuffer:GL_RENDERBUFFER];
        glBindRenderbuffer(GL_RENDERBUFFER, 0);
    }
}

-(BOOL)CompileShader:(char*)shadersource shader:(GLuint)shader
{
    glShaderSource(shader, 1, (const char**)&shadersource, NULL);
    glCompileShader(shader);
    
    GLint compiled = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    
    if(!compiled)
    {
        int length = MAX_SIZE;
        char log[MAX_SIZE] = {0};
        
        glGetShaderInfoLog(shader, length, &length, log);
        NSLog(@"Shader compile failed");
        NSLog(@"log: %@", [NSString stringWithUTF8String:log]);
        
        return NO;
    }
    
    return YES;
}

-(BOOL)LoadShaders:(char*)vssource fragsource:(char*)fssource program:(GLuint*)prog
{
    GLuint vs = glCreateShader(GL_VERTEX_SHADER);
    GLuint fs = glCreateShader(GL_FRAGMENT_SHADER);
    
    if (!prog)
    {
        return NO;
    }
    
    if (!(vs && fs))
    {
        NSLog(@"Create Shader failed");
        return NO;
    }
    
    if (![self CompileShader:vssource shader:vs])
    {
        return NO;
    }
    
    if (![self CompileShader:fssource shader:fs])
    {
        return NO;
    }
    
    *prog = glCreateProgram();
    
    if (!(*prog))
    {
        NSLog(@"Create program failed");
        return NO;
    }
    
    glAttachShader(*prog, vs);
    glAttachShader(*prog, fs);
    glLinkProgram(*prog);
    
    GLint linked = 0;
    glGetProgramiv(*prog, GL_LINK_STATUS, &linked);
    if(!linked)
    {
        NSLog(@"Link program failed");
        return NO;
    }
    return YES;
}

@end
