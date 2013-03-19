//
//  Solver.m
//  СС1
//
//  Created by Pavel Aksenkin on 24.02.13.
//  Copyright (c) 2013 Pavel Aksenkin. All rights reserved.
//

#import "Solver.h"

//#define nlog(A) [_log setString:[_log.string stringByAppendingFormat:@"%@\n", A]];
#define nlog(A) [_log setString:[NSString stringWithFormat:@"%@\n%@", A, _log.string]];
#define nlog2(A, B) [_log setString:[NSString stringWithFormat:@"%@\n%@\n%@", A, B, _log.string]];

@implementation Solver

-(void)solve:(id)sender
{
    [_log setString:@""];
//    Grammar *grammar = [[Grammar alloc] initWithStrings:strArray];
    Grammar *grammar = [[Grammar alloc] initWithStrings:[_grController strings]];
    
    FA *fa = [[FA alloc] initWithLeftLinear:grammar];
    nlog2(@"Промежуточный автомат", fa);
    
    Grammar *right = [fa rightLinear];
//    NSLog(@"%@", right);
    
    nlog2(@"Праволинейная грамматика:", right);
    
    RSystem *system = [[RSystem alloc] initWithGrammar:right];
    nlog(system);
    
    Regexp *result = [system solveForAxiom:right.axiom];
    nlog2(@"Система после решения:", system);
    nlog2(@"Решение", result);
    
    FA *fa2 = [FA faWithRegexp:result];
    nlog2(@"НКА", fa2);
    
    [fa2 determinate];
    nlog2(@"ДКА:", fa2);
    _fa = fa2;
}
-(void)isAllowed:(id)sender
{
    if (!_fa) {
        [self solve:sender];
    }
    
    NSString *chain = _expField.stringValue;
    NSDate *a = [NSDate date];
    NSDictionary *dic = [_fa isAllowed:chain];
    NSDate *b = [NSDate date];
    if (dic[@"error"]) {
        nlog(dic[@"error_description"]);
    } else {
        nlog2(@"Вывод:", dic[@"output"]);
        NSString *result = [NSString stringWithFormat:@"Цепочка '%@' %@",
                            chain.length > 0 ? chain : kEmptyString,
                            [dic[@"isAllowed"] intValue] ? @"допустима" : @"недопустима"];
        nlog(result);
    }
    NSLog(@"Spent time: %f", b.timeIntervalSince1970 - a.timeIntervalSince1970);
}


-(void)awakeFromNib
{
    [_log setEditable:NO];
    [_log setSelectable:NO];
}

@end
