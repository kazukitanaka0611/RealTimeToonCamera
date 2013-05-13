//
//  ToonFilterOpengGLView.m
//  RealTimeToonCamera
//
//  Created by kazuki_tanaka on 2013/05/12.
//  Copyright (c) 2013年 kazukitanaka. All rights reserved.
//

#import "ToonFilterOpengGLView.h"

@interface ToonFilterOpengGLView()

@end

@implementation ToonFilterOpengGLView

#pragma mark -
- (NSString *)getVertexShaderString
{
    NSString *const kVertexShaderString = SHADER_STRING
    (
     attribute vec4 position;
     attribute vec4 inputTextureCoordinate;
     
     uniform lowp float mirror;
     uniform float texelWidth;
     uniform float texelHeight;

     varying vec2 textureCoordinate;
     varying vec2 leftTextureCoordinate;
     varying vec2 rightTextureCoordinate;

     varying vec2 topTextureCoordinate;
     varying vec2 topLeftTextureCoordinate;
     varying vec2 topRightTextureCoordinate;

     varying vec2 bottomTextureCoordinate;
     varying vec2 bottomLeftTextureCoordinate;
     varying vec2 bottomRightTextureCoordinate;

     void main()
     {
         highp vec4 pos = position;
         pos.x *= mirror;
         
         gl_Position = pos;

         vec2 widthStep = vec2(texelWidth, 0.0);
         vec2 heightStep = vec2(0.0, texelHeight);
         vec2 widthHeightStep = vec2(texelWidth, texelHeight);
         vec2 widthNegativeHeightStep = vec2(texelWidth, -texelHeight);

         textureCoordinate = inputTextureCoordinate.xy;
         leftTextureCoordinate = inputTextureCoordinate.xy - widthStep;
         rightTextureCoordinate = inputTextureCoordinate.xy + widthStep;

         topTextureCoordinate = inputTextureCoordinate.xy - heightStep;
         topLeftTextureCoordinate = inputTextureCoordinate.xy - widthHeightStep;
         topRightTextureCoordinate = inputTextureCoordinate.xy + widthNegativeHeightStep;

         bottomTextureCoordinate = inputTextureCoordinate.xy + heightStep;
         bottomLeftTextureCoordinate = inputTextureCoordinate.xy - widthNegativeHeightStep;
         bottomRightTextureCoordinate = inputTextureCoordinate.xy + widthHeightStep;
     }
     );

    return kVertexShaderString;
}

#pragma mark -
- (NSString *)getFragmentShaderString
{
    NSString *const kFragmentShaderString = SHADER_STRING
    (
     precision highp float;

     varying vec2 textureCoordinate;
     varying vec2 leftTextureCoordinate;
     varying vec2 rightTextureCoordinate;

     varying vec2 topTextureCoordinate;
     varying vec2 topLeftTextureCoordinate;
     varying vec2 topRightTextureCoordinate;

     varying vec2 bottomTextureCoordinate;
     varying vec2 bottomLeftTextureCoordinate;
     varying vec2 bottomRightTextureCoordinate;

     uniform sampler2D inputImageTexture;

     uniform highp float intensity;
     uniform highp float threshold;
     uniform highp float quantizationLevels;

     const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);

     void main()
     {
         vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);

         float bottomLeftIntensity = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
         float topRightIntensity = texture2D(inputImageTexture, topRightTextureCoordinate).r;
         float topLeftIntensity = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
         float bottomRightIntensity = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
         float leftIntensity = texture2D(inputImageTexture, leftTextureCoordinate).r;
         float rightIntensity = texture2D(inputImageTexture, rightTextureCoordinate).r;
         float bottomIntensity = texture2D(inputImageTexture, bottomTextureCoordinate).r;
         float topIntensity = texture2D(inputImageTexture, topTextureCoordinate).r;
         float h = -topLeftIntensity - 2.0 * topIntensity - topRightIntensity + bottomLeftIntensity + 2.0 * bottomIntensity + bottomRightIntensity;
         float v = -bottomLeftIntensity - 2.0 * leftIntensity - topLeftIntensity + bottomRightIntensity + 2.0 * rightIntensity + topRightIntensity;

         float mag = length(vec2(h, v));

         vec3 posterizedImageColor = floor((textureColor.rgb * quantizationLevels) + 0.5) / quantizationLevels;
         
         float thresholdTest = 1.0 - step(threshold, mag);
         
         gl_FragColor = vec4(posterizedImageColor * thresholdTest, textureColor.a);
     }
     );

    return kFragmentShaderString;
}

#pragma mark -
- (void)setUniform
{
    glUniform1f(glGetUniformLocation(self.programHandle, "texelWidth"), 1.0 / self.frame.size.width);
    glUniform1f(glGetUniformLocation(self.programHandle, "texelHeight"), 1.0 / self.frame.size.height);
    glUniform1f(glGetUniformLocation(self.programHandle, "threshold"), 0.2);
    glUniform1f(glGetUniformLocation(self.programHandle, "quantizationLevels"), 10.0);
}

@end
