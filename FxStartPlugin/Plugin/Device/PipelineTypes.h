//
//  PipelineTypes.h
//  FxStartPlugin
//
//  Created by Kacper  on 03/09/2024.
//

#ifndef PipelineTypes_h
#define PipelineTypes_h

typedef enum PipelineTypes{
    PT_None = 0,
    PT_Brightness = 1,
    PT_Negative = 2,
    PT_GaussianBlur = 3,
    PT_KawaseBlur = 4,
    PT_BoxBlur = 5,
    
    PT_OilPainting = 100,
} PipelineTypes;

#endif /* PipelineTypes_h */
