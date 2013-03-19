//
//  RSystem.h
//  СС1
//
//  Created by Pavel Aksenkin on 24.02.13.
//  Copyright (c) 2013 Pavel Aksenkin. All rights reserved.
//

#import "Grammar.h"
#import "Regexp.h"

@interface RSystem : NSObject
{
    NSMutableDictionary *_equas;
}
-(RSystem*)initWithGrammar:(Grammar*)grammar;
-(Regexp*)solveForAxiom:(NSString*)axiom;

@end
