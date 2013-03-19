//
//  Grammar.m
//  СС1
//
//  Created by Pavel Aksenkin on 24.02.13.
//  Copyright (c) 2013 Pavel Aksenkin. All rights reserved.
//

#import "Grammar.h"


@implementation Rule
@synthesize antecedent = _antecedent;
@synthesize consequent = _consequent;

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ -> %@", _antecedent, _consequent];
}
-(id)copy
{
    Rule *rule = [[Rule alloc] init];
    rule->_antecedent = self->_antecedent;
    rule->_consequent = self->_consequent;
    return rule;
}
@end

@implementation Grammar

NSString * const kNTerminals  = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
NSString * const kTerminals = @"abcdefghijklmnopqrstuvwxyz";
NSString * const kEmptyString = @"λ";

-(Grammar *)initWithStrings:(NSArray *)strings axiom:(NSString *)axiom
{
    self = [self initWithStrings:strings];
    if (self) {
        _axiom = axiom;
    }
    return self;
}
-(Grammar *)initWithStrings:(NSArray *)strings
{
    self = [super init];
    if (self) {
        _terms = [[NSMutableArray alloc] init];
        _nterms = [[NSMutableArray alloc] init];
        _rules = [[NSMutableArray alloc] init];
        for (NSString *str in strings) {
            NSArray * comps = [str componentsSeparatedByString:@"->"];
            assert(comps.count == 2);
            Rule *rule = [[Rule alloc] init];
            rule.antecedent = [comps[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            rule.consequent = [comps[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [_rules addObject:rule];
            for(NSUInteger i=0; i<rule.antecedent.length; ++i) {
                NSString *symbol = [rule.antecedent substringWithRange:NSMakeRange(i, 1)];
                if ([kNTerminals rangeOfString:symbol].location != NSNotFound) {
                    if (![_nterms containsObject:symbol]) {
                        [_nterms addObject:symbol];
                    }
                } else {
                    NSLog(@"Antecedent contains forbidden symbols");
                }
            }
            for(NSUInteger i=0; i<rule.consequent.length; ++i) {
                NSString *symbol = [rule.consequent substringWithRange:NSMakeRange(i, 1)];
                if ([kNTerminals rangeOfString:symbol].location != NSNotFound) {
                    if (![_nterms containsObject:symbol]) {
                        [_nterms addObject:symbol];
                    }
                } else if ([kTerminals rangeOfString:symbol].location != NSNotFound) {
                    if (![_terms containsObject:symbol]) {
                        [_terms addObject:symbol];
                    }
                } else if (![symbol isEqualToString:kEmptyString]) {
                    NSLog(@"Consequent contains forbidden symbols");
                }
            }
            
            if ([_nterms containsObject:@"S"]) {
                _axiom = @"S";
            } else if ([_nterms containsObject:@"A"]) {
                _axiom = @"A";
            } else {
                _axiom = _nterms[0];
            }
        }
    }
    
    return self;
}

-(void)cleanLinear
{
        // Нет цепных правил, алгоритм куда проще
    NSMutableArray *emptyNTerms = [NSMutableArray array];
    for (NSUInteger i=0; i<_rules.count; ) {
        Rule *rule = _rules[i];
        if (![rule.antecedent isEqualToString:_axiom] && [rule.consequent isEqualToString:kEmptyString]) {
            [emptyNTerms addObject:rule.antecedent];
            [_rules removeObjectAtIndex:i];
        } else {
            ++i;
        }
    }
    
        // Обновляем список нетерминалов, чтобы удалить бесполезные по для новых правил
    [_nterms removeAllObjects];
    for(Rule *rule in _rules) {
        NSString *symbol = rule.antecedent;
        if ([kNTerminals rangeOfString:symbol].location != NSNotFound) {
            if (![_nterms containsObject:symbol]) {
                [_nterms addObject:symbol];
            }
        } else {
            NSLog(@"Antecedent contains forbidden symbols");
        }
    }
    
    NSUInteger oldCount = _rules.count;
    for(NSUInteger i=0; i<oldCount; ++i) {
        Rule *rule = _rules[i];
        for (NSString *nterm in emptyNTerms) {
            NSRange range = [rule.consequent rangeOfString:nterm];
            if (range.location != NSNotFound) {
                if ([_nterms containsObject:nterm]) {
                    Rule *newRule = [[Rule alloc] init];
                    newRule.antecedent = rule.antecedent;
                    newRule.consequent = [rule.consequent stringByReplacingOccurrencesOfString:nterm withString:@""];
                    [_rules addObject:newRule];
                } else {
                    rule.consequent = [rule.consequent stringByReplacingOccurrencesOfString:nterm withString:@""];
                }
            }
        }
    }
}

-(NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"%@", [super description]];
    
    NSMutableString *terms = [[NSMutableString alloc] initWithString:@"Терминалы: "];
    for (NSString *term in _terms) {
        [terms appendString:term];
    }
    [description appendFormat:@"\n%@", terms];
    
    NSMutableString *nterms = [[NSMutableString alloc] initWithString:@"Нетерминалы: "];
    for (NSString *nterm in _nterms) {
        [nterms appendString:nterm];
    }
    [description appendFormat:@"\n%@", nterms];
    [description appendFormat:@"\nАксиома: %@", _axiom];
    
    [description appendString:@"\nПравила: "];
    for (Rule *rule in _rules) {
        [description appendFormat:@"\n%@", rule];
    }
    [description appendString:@"\n\n"];
    
    return description;
}

#pragma mark getters
-(NSArray *)terms
{
    return [NSArray arrayWithArray:_terms];
}
-(NSArray *)nterms
{
    return [NSArray arrayWithArray:_nterms];
}
-(NSString *)axiom
{
    return _axiom;
}
-(NSArray *)rules
{
    return [NSArray arrayWithArray:_rules];
}

@end
