//
//  RSystem.m
//  СС1
//
//  Created by Pavel Aksenkin on 24.02.13.
//  Copyright (c) 2013 Pavel Aksenkin. All rights reserved.
//

#import "RSystem.h"

@implementation RSystem
-(RSystem *)initWithGrammar:(Grammar *)grammar
{
//    _equas = @{ NSString => @{ NSString => Regexp, ... }, ... }
    self = [super init];
    if (self) {
        _equas = [NSMutableDictionary dictionary];
        for(Rule *rule in grammar.rules) {
            NSString *nterm = rule.antecedent;
            NSUInteger len = rule.consequent.length;
            NSString *rnterm = [rule.consequent substringFromIndex:len-1];
            NSString *regex;
            if ([kNTerminals rangeOfString:rnterm].location != NSNotFound) {
                regex = [rule.consequent substringToIndex:len-1];
            } else {
                rnterm = @"";
                regex = rule.consequent;
            }
            
            NSMutableDictionary *equa;
            if (!(equa = _equas[nterm])) {
                equa = [NSMutableDictionary dictionary];
                [_equas setObject:equa forKey:nterm];
            }
            if ([equa objectForKey:rnterm]) {
                [equa setObject:[RegexpBinar orArray:@[[equa objectForKey:rnterm], [RegexpBinar chain:regex]]] forKey:rnterm];
            } else {
                [equa setObject:[RegexpBinar chain:regex] forKey:rnterm];
            }

        }
    }
    return self;
}
-(Regexp *)solveForAxiom:(NSString *)axiom
{
    for (NSString *nkey in _equas) {                // По всем уравнениям
        NSMutableDictionary *equa = _equas[nkey];
        if ([equa objectForKey:nkey]) {             // Если уравнение вида C = αC + β
            RegexpUnar *iter = [RegexpUnar iter:[equa objectForKey:nkey]];
            [equa removeObjectForKey:nkey];
            
                // Упадет, если тут не помухлевать, нельзя изменять коллекцию во время итерации
            NSMutableDictionary *equaCopy = [equa copy];
            for (NSString *rkey in equaCopy) {          // По уравнению equa, делаем C = α*β
                Regexp *beta = equaCopy[rkey];
                Regexp *combined = [RegexpBinar concatArray:@[iter, beta]];
                [equa setObject:combined forKey:rkey];
            }
        }
        
        for (NSString *nkey2 in _equas) {       // По всем уравнениям...
            NSMutableDictionary *equa2 = _equas[nkey2];
            for (NSString *rkey2 in equa2) {    // По уравнению,
                if ([rkey2 isEqualToString:nkey]) {         // где есть вхождение C в правую часть
                    NSString *beta = equa2[nkey];
                    [equa2 removeObjectForKey:nkey];
                    for (NSString *rkey3 in equa) {         // По всем слагаемым в α*β
                        if ([equa2 objectForKey:rkey3]) {   // αB + βC = αB + β(γB + δ) = (α+βγ)B + βδ 
                            Regexp *alpha = [equa2 objectForKey:rkey3];
                            Regexp *gamma = [equa objectForKey:rkey3];
                            Regexp *combined = [RegexpBinar orArray:@[alpha, [RegexpBinar concatArray:@[beta, gamma]]]];
                            [equa2 setObject:combined forKey:rkey3];
                        } else {    // βC = β(γB + δ) = βγB + βδ, верно и для B = @""
                            Regexp *gamma = [equa objectForKey:rkey3];
                            Regexp *combined = [RegexpBinar concatArray:@[beta, gamma]];
                            [equa2 setObject:combined forKey:rkey3];
                        }
                    }
                    break;
                }
            }
        }
    }
    NSMutableDictionary *axiomEqua = _equas[axiom];
    return axiomEqua[@""];
}
-(NSString *)description
{
    NSMutableString *result = [NSMutableString stringWithFormat:@"Система:"];
    for (NSString *nterm in _equas) {
        NSMutableString *string = [NSMutableString stringWithFormat:@"%@ = ", nterm];
        BOOL isFirst = YES;
        NSMutableDictionary *equa = _equas[nterm];
        for (NSString *rnterm in equa) {
            NSString *multy = [equa[rnterm] ssercDescription];
            if ([multy rangeOfString:@"+"].location != NSNotFound) {
                multy = [NSString stringWithFormat:@"(%@)", multy];
            }
            [string appendFormat:@"%@ %@%@", isFirst ? @"" : @" + ", multy, rnterm];
            isFirst = NO;
        }
        [result appendFormat:@"\n%@", string];
    }
    return result;
}

@end
