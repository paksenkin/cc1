//
//  Grammar.h
//  СС1
//
//  Created by Pavel Aksenkin on 24.02.13.
//  Copyright (c) 2013 Pavel Aksenkin. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kTerminals;
extern NSString * const kNTerminals;
extern NSString * const kEmptyString;

@interface Rule : NSObject

@property (copy) NSString *antecedent;
@property (copy) NSString *consequent;

@end

@interface Grammar : NSObject
{
    NSMutableArray *_terms;
    NSMutableArray *_nterms;
    NSString *_axiom;
    NSMutableArray *_rules;
}
-(Grammar*)initWithStrings:(NSArray*)strings;
-(Grammar*)initWithStrings:(NSArray *)strings axiom:(NSString*)axiom;

-(void)cleanLinear;

-(NSArray*)terms;
-(NSArray*)nterms;
-(NSString*)axiom;
-(NSArray*)rules;

@end
