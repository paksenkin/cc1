//
//  FA.m
//  СС1
//
//  Created by Pavel Aksenkin on 24.02.13.
//  Copyright (c) 2013 Pavel Aksenkin. All rights reserved.
//

#import "FA.h"

@implementation Arc

@synthesize from = _from;
@synthesize to = _to;
@synthesize symbol = _symbol;

NSString * const kStateNames = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
static NSUInteger _usedStates;

-(Arc *)initWithFrom:(NSString *)from symbol:(NSString *)symbol to:(NSString *)to
{
    self = [super init];
    if (self) {
        _from = from;
        _to = to;
        _symbol = symbol;
    }
    return self;
}
-(id)copy
{
    Arc *arc = [super copy];
    arc->_from = _from;
    arc->_to = _to;
    arc->_symbol = _symbol;
    return arc;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ -(%@)-> %@", _from, _symbol, _to];
}

@end

@implementation FA

    // Читерский автомат, допускающий переходы по строке.
    // Для преобразования грамматики как раз подойдет
+(FA *)faWithLeftLinear:(Grammar *)grammar
{
    return [[FA alloc] initWithLeftLinear:grammar];
}
-(FA *)initWithLeftLinear:(Grammar *)grammar
{
    self = [super init];
    if (self) {
        _alphabet = [[NSMutableArray alloc] initWithArray:grammar.terms];
        _states = [[NSMutableArray alloc] initWithArray:grammar.nterms];
        NSString *newStart;
            // Новое начальное состояние
        for(NSUInteger i=0; i<kNTerminals.length; ++i) {
            NSString *symbol = [kNTerminals substringWithRange:NSMakeRange(i, 1)];
            if (![_states containsObject:symbol]) {
                newStart = symbol;
                break;
            }
        }
        assert(newStart);
        [_states addObject:newStart];
        _initStates = [[NSMutableArray alloc] initWithObjects:newStart, nil];
        _finStates = [[NSMutableArray alloc] initWithObjects:grammar.axiom, nil];
        
        _transes = [NSMutableArray array];
        for (Rule *rule in grammar.rules) {
            Arc *arc;
            NSString *firstSymbol = [rule.consequent substringToIndex:1];
            if ([kNTerminals rangeOfString:firstSymbol].location != NSNotFound) {    // A->Bα
                NSString *to = [rule.antecedent copy];
                NSString *from = [rule.consequent substringToIndex:1];
                NSString *symbol = [rule.consequent substringFromIndex:1];
                arc = [[Arc alloc] initWithFrom:from symbol:symbol to:to];
            } else if ([firstSymbol isEqualToString:kEmptyString] || [kTerminals rangeOfString:firstSymbol].location != NSNotFound) {   // A->γ
                NSString *to = [rule.antecedent copy];
                NSString *from = newStart;
                NSString *symbol = [rule.consequent copy];
                arc = [[Arc alloc] initWithFrom:from symbol:symbol to:to];
            } else {
                NSLog(@"Unexpected rule: %@", rule);
            }
            if (arc) [_transes addObject:arc];
        }
        [self _removeEmpty];
    }
    return self;
}

+(FA *)faWithRegexp:(Regexp *)regexp
{
    return [[FA alloc] initWithRegexp:regexp];
}
-(FA *)initWithRegexp:(Regexp *)regexp
{
    _usedStates = 0;
    return [self initWithRegexp1:regexp];
}
-(id)copy
{
    FA *res = [super copy];
    [res copyFrom:self];
    return res;
}
-(void)copyFrom:(FA*)fa
{
    _alphabet = [fa->_alphabet mutableCopy];
    _states = [fa->_states mutableCopy];
    _initStates = [fa->_initStates mutableCopy];
    _finStates = [fa->_finStates mutableCopy];
    _transes = [fa->_transes mutableCopy];
}

-(Grammar *)rightLinear
{
//    [self _removeEmpty];
    NSMutableArray *strings = [NSMutableArray array];
    for (Arc *arc in _transes) {
        NSString *rule = [arc.symbol isEqualToString:kEmptyString] ? [NSString stringWithFormat:@"%@ -> %@", arc.from, arc.to] : [NSString stringWithFormat:@"%@ -> %@%@", arc.from, arc.symbol, arc.to];
        [strings addObject:rule];
    }
    for(NSString *state in _finStates) {
        NSString *rule = [NSString stringWithFormat:@"%@ -> %@", state, kEmptyString];
        [strings addObject:rule];
    }
    NSString *axiom = _initStates[0];
    Grammar *result = [[Grammar alloc] initWithStrings:strings axiom:axiom];
    [result cleanLinear];
    return result;
}

-(NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"%@", [super description]];
    
    NSMutableString *states = [[NSMutableString alloc] initWithString:@"Состояния: "];
    [states appendString:[_states componentsJoinedByString:@", "]];
    [description appendFormat:@"\n%@", states];
    
    NSMutableString *alph = [[NSMutableString alloc] initWithString:@"Алфавит: "];
    [alph appendString:[_alphabet componentsJoinedByString:@", "]];
    [description appendFormat:@"\n%@", alph];
    
    NSMutableString *inStates = [[NSMutableString alloc] initWithString:@"Начальные: "];
    [inStates appendString:[_initStates componentsJoinedByString:@", "]];
    [description appendFormat:@"\n%@", inStates];
    
    NSMutableString *finStates = [[NSMutableString alloc] initWithString:@"Конечные: "];
    [finStates appendString:[_finStates componentsJoinedByString:@", "]];
    [description appendFormat:@"\n%@", finStates];
    
    [description appendString:@"\nПереходы: "];
    for (Arc *arc in _transes) {
        [description appendFormat:@"\n%@", arc];
    }
    
    return description;
}

#pragma mark Regexp
-(FA *)initWithRegexp1:(Regexp *)regexp
{
    self = [super init];
    if (self) {
        switch (regexp.oper) {
            case RegexpOperSymbol:
                [self _faSymbol:(RegexpSymbol*)regexp];
                break;
            case RegexpOperConcat:
            case RegexpOperOr:
                [self _faBinar:(RegexpBinar*)regexp];
                break;
            case RegexpOperIter:
                [self _faUnar:(RegexpUnar *)regexp];
                break;
            default:
                self = nil;
        }
    }
    return self;
}
-(void)_faSymbol:(RegexpSymbol*)regexp
{
    if ([regexp.symbol isEqualToString:kEmptyString]) {
        _alphabet = [NSMutableArray array];
        _transes = [NSMutableArray array];
        _states = [NSMutableArray array];
        [_states addObject:[self _newState]];
        _initStates = [_states mutableCopy];
        _finStates = [_states mutableCopy];
    } else {
        _alphabet = [NSMutableArray arrayWithObject:regexp.symbol];
        _states = [NSMutableArray array];
        
        _initStates = [NSMutableArray array];
        [_initStates addObject:[self _newState]];
        [_states addObjectsFromArray:_initStates];
        
        _finStates = [NSMutableArray array];
        [_finStates addObject:[self _newState]];
        [_states addObjectsFromArray:_finStates];
        
        Arc *arc = [[Arc alloc] initWithFrom:_initStates[0] symbol:regexp.symbol to:_finStates[0]];
        _transes = [NSMutableArray array];
        [_transes addObject:arc];
    }
}
-(void)_faBinar:(RegexpBinar*)regexp
{
    NSMutableArray *fas = [NSMutableArray array];
    for (Regexp *r in regexp.operands) {
        [fas addObject:[[FA alloc] initWithRegexp1:r]];
    }
    if (regexp.oper == RegexpOperOr) {
        _alphabet = [NSMutableArray array];
        _states = [NSMutableArray array];
        _finStates = [NSMutableArray array];
        NSString *newStart = [self _newState];
        _transes = [NSMutableArray array];
        _initStates = [NSMutableArray arrayWithObject:newStart];
        for (FA *fa in fas) {
            [self _concatSet:fa->_alphabet toSet:_alphabet];
            [self _concatSet:fa->_states toSet:_states];
            [self _concatSet:fa->_finStates toSet:_finStates];
            [_transes addObjectsFromArray:fa->_transes];
            for (NSString *state in fa->_initStates) {
                Arc *arc = [[Arc alloc] initWithFrom:newStart symbol:kEmptyString to:state];
                [_transes addObject:arc];
            }
        }
    } else {
        [self copyFrom:fas[0]];
        for (NSUInteger i=1; i<fas.count; ++i) {
            FA *fa = fas[i];
            [self _concatSet:fa->_alphabet toSet:_alphabet];
            [self _concatSet:fa->_states toSet:_states];
            [_transes addObjectsFromArray:fa->_transes];
            for (NSString *a in self->_finStates) {
                for(NSString *b in fa->_initStates) {
                    Arc *arc = [[Arc alloc] initWithFrom:a symbol:kEmptyString to:b];
                    [_transes addObject:arc];
                }
            }
            _finStates = [fa->_finStates mutableCopy];
        }
    }
}
-(void)_faUnar:(RegexpUnar*)regexp
{
    FA *supFA = [[FA alloc] initWithRegexp1:regexp.left];
    _alphabet = [supFA->_alphabet mutableCopy];
    _states = [supFA->_states mutableCopy];
    _initStates = [supFA->_initStates mutableCopy];
    _finStates = [supFA->_finStates mutableCopy];
    _transes = [supFA->_transes mutableCopy];
    
    for (NSString *b in _initStates) {
        for (NSString *a in _finStates) {
            Arc *arc = [[Arc alloc] initWithFrom:a symbol:kEmptyString to:b];
            [_transes addObject:arc];
        }
    }
        // Нужно сделать начальное все начальные состояния конечными
    [self _concatSet:_initStates toSet:_finStates];
}
-(NSString*)_newState
{
    return [self _stateForInt:_usedStates++];
}

#pragma mark Determinate
-(void)determinate
{
    [self _makeOneInput];
    [self _removeEmpty];
    [self _reallyDeterminate];
}
-(void)_makeOneInput
{
    if (_initStates.count > 1) {
        NSString *newState = [self _newState];
        [_states addObject:newState];
        for (NSString *state in _initStates) {
            Arc *arc = [[Arc alloc] initWithFrom:newState symbol:kEmptyString to:state];
            [_transes addObject:arc];
        }
        [_initStates removeAllObjects];
        [_initStates addObject:newState];
    }
}
-(void)_removeEmpty
{
        // 1.Удалить все состояния, в которые входят дуги с kEmptyString
        // Также построить
    [_states removeAllObjects];
    [_states addObjectsFromArray:_initStates];
    NSMutableDictionary *reachEmpty = [NSMutableDictionary dictionary];
    NSMutableArray *newTrances = [NSMutableArray array];
    for (Arc *arc in _transes) {
        if (![arc.symbol isEqualToString:kEmptyString]) {
            [newTrances addObject:arc];
            if (![self array:_states containsString:arc.to]) {
                [_states addObject:arc.to];
            }
        } else {
            NSMutableArray *set = [reachEmpty objectForKey:arc.from];
            if (!set) {
                set = [NSMutableArray arrayWithObject:arc.from];
            }
            [set addObject:arc.to];
            [reachEmpty setObject:set forKey:arc.from];
        }
    }
    _transes = [newTrances copy];
    
        // 2. Замкнуть множество достижимости по пустой строке
    BOOL wasExtended = YES;
    for(NSString *i in _states) {
        if (!reachEmpty[i]) {
            [reachEmpty setObject:[NSMutableArray arrayWithObject:i] forKey:i];
        }
    }
    while(wasExtended) {
        wasExtended = NO;
        for (NSString *i in reachEmpty) {
            NSMutableArray *set = reachEmpty[i];
                // Добавить себя, рефлексивно-транзитивное замыкание же
//            if (![self array:set containsString:i]) {
//                [set addObject:i];
//            }
            NSMutableArray *oldSet = [set copy];
            for (NSString *j in oldSet) {
                NSMutableArray *set2 = reachEmpty[j];
                for(NSString *k in set2) {
                    if (![self array:set containsString:k]) {
                        [set addObject:k];
                        wasExtended = YES;
                    }
                }
            }
        }
    }
    NSLog(@"%@", reachEmpty);
    
        // 3. Для всех p, r из _states(Q') добавить все возможные дуги, где p-\/->r по символу a или
        //    по цепочке из пустых строк и символа a
    [newTrances removeAllObjects];
    for (NSString *p in _states) {
        for (NSString *r in _states) {
            for (NSString *q in reachEmpty[p]) {
                for (Arc *arc in [self arcsFrom:q to:r]) {
                    Arc *newArc = [[Arc alloc] initWithFrom:p symbol:arc.symbol to:r];
                    [newTrances addObject:newArc];
                }
            }
        }
    }
    _transes = [newTrances copy];
    
        // 4. Для всех p из _states(Q') найти новые заключительные состояния
    NSMutableArray *newFin = [NSMutableArray array];
    for (NSString *p in _states) {
        for(NSString *q in reachEmpty[p]) {
            if ([self array:_finStates containsString:q] && ![self array:newFin containsString:p]) {
                [newFin addObject:p];
                break;
            }
        }
    }
    for (NSString *p in _finStates) {
        if ([self array:_states containsString:p] && ![self array:newFin containsString:p]) {
            [newFin addObject:p];
        }
    }
    _finStates = [newFin copy];
}
-(void)_reallyDeterminate
{
    NSMutableArray *newStates = [NSMutableArray array];
    [newStates addObject:[NSMutableArray arrayWithObject:_initStates[0]]];
    NSMutableArray *newTranses = [NSMutableArray array];
    
    BOOL wasModified = YES;
    while(wasModified) {
        wasModified = NO;
        for (NSUInteger i=0; i < newStates.count; ++i) {        // Для каждого нового состояния
            NSMutableArray *set = newStates[i];
            for (NSString *symbol in _alphabet) {               // По каждому символу
                NSMutableArray *newSet = [NSMutableArray array];// Строим новое подмножество
                for(NSMutableString *from in set) {
                    for (Arc *arc in [self arcsFrom:from by:symbol]) {
                        if (![self array:newSet containsString:arc.to]) {
                            [newSet addObject:arc.to];
                        }
                    }
                }
                NSInteger j = [self array:newStates indexOfSet:newSet];
                if (j == -1) {
                    j = newStates.count;
                    [newStates addObject:newSet];
                    wasModified = YES;
                }
                NSString *iName = [self _stateForInt:i];
                NSString *jName = [self _stateForInt:j];
                Arc *newArc = [[Arc alloc] initWithFrom:iName symbol:symbol to:jName];
                if (![self array:newTranses containsArc:newArc]) {
                    [newTranses addObject:newArc];
                }
            }
        }
    }
    
    [_states removeAllObjects];
    [_initStates removeAllObjects];
    [_initStates addObject:[self _stateForInt:0]];
    _transes = [newTranses copy];
    NSMutableArray *newFinStates = [NSMutableArray array];
    for (NSUInteger i=0; i<newStates.count; ++i) {
        NSString *curState = [self _stateForInt:i];
        [_states addObject:curState];
        for (NSString *state in newStates[i]) {
            if ([self array:_finStates containsString:state]) {
                [newFinStates addObject:curState];
                break;
            }
        }
    }
    _finStates = newFinStates;
}

#pragma mark isAllowed
-(NSDictionary*)isAllowed:(NSString *)chain
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    @try {
        NSMutableString *output = [NSMutableString string];
        NSString *curState = _initStates[0];    // После детерминирования должно быть одно
        [output appendString:curState];
        BOOL wasBroken = NO;
        for(NSUInteger i=0; i<chain.length; ++i) {
            NSString *symbol = [chain substringWithRange:NSMakeRange(i, 1)];
            NSArray *arcs = [self arcsFrom:curState by:symbol];
            if (arcs.count != 1) { // После детерминирования всегда одно
                wasBroken = YES;
                break;
            }
            Arc *arc = arcs[0];   
            curState = arc.to;
            if (curState.length > 1) {
                [output appendFormat:@"(%@)", curState];
            } else {
                [output appendString:curState];
            }
        }
        
        if (wasBroken) {
            [result setObject:@0 forKey:@"isAllowed"];
            [result setObject:@"Встречены символы не из алфавита" forKey:@"output"];
        } else {
            [result setObject:output forKey:@"output"];
            if ([self array:_finStates containsString:curState]) {
                [result setObject:@1 forKey:@"isAllowed"];
            } else {
                [result setObject:@0 forKey:@"isAllowed"];
            }
        }
        
    }
    @catch (NSException *exception) {
        NSLog(@"Exception %@", exception);
        [result setObject:@0 forKey:@"error"];
        [result setObject:@"Ошибка ввода" forKey:@"error_description"];
        [result setObject:exception forKey:@"error_exception"];
    }
    return [NSDictionary dictionaryWithDictionary:result];
}

#pragma mark Helpful
-(NSArray*)arcsFrom:(NSString*)from to:(NSString*)to
{
    NSMutableArray *arr;
    for (Arc *arc in _transes) {
        if ([arc.from isEqualToString:from] && [arc.to isEqualToString:to]) {
            if (!arr) {
                arr = [NSMutableArray arrayWithObject:arc];
            } else {
                [arr addObject:arc];
            }
        }
    }
    return [NSArray arrayWithArray:arr];
}
-(NSArray*)arcsFrom:(NSString*)from by:(NSString*)symbol
{
    NSMutableArray *arr;
    for (Arc *arc in _transes) {
        if ([arc.from isEqualToString:from] && [arc.symbol isEqualToString:symbol]) {
            if (!arr) {
                arr = [NSMutableArray arrayWithObject:arc];
            } else {
                [arr addObject:arc];
            }
        }
    }
    return [NSArray arrayWithArray:arr];
}
-(BOOL)array:(NSMutableArray*)arr containsString:(NSString*)str
{
    BOOL result = NO;
    for (NSString *i in arr) {
        if ([i isEqualToString:str]) {
            result = YES;
            break;
        }
    }
    return result;
}
-(NSInteger)array:(NSMutableArray*)arr indexOfSet:(NSMutableArray*)set
{
    NSInteger result = -1;
    for (NSUInteger i=0; i<arr.count; ++i) {
        if([self isSet:set equalToSet:arr[i]]) {
            result = i;
            break;
        }
    }
    return result;
}
-(BOOL)array:(NSMutableArray*)arr containsArc:(Arc *)arc
{
    BOOL result = NO;
    for (Arc *anotherArc in arr) {
        if ([arc.from isEqualToString:anotherArc.from] && [arc.to isEqualToString:anotherArc.to] && [arc.symbol isEqualToString:anotherArc.symbol]) {
            result = YES;
            break;
        }
    }
    return result;
}
-(BOOL)isSet:(NSMutableArray*)a equalToSet:(NSMutableArray*)b
{
    BOOL result = YES;
    if (a.count == b.count) {
        for (NSString *x in a) {
            if (![self array:b containsString:x]) {
                result = NO;
                break;
            }
        }
    } else {
        result = NO;
    }
    return result;
}
-(void)_concatSet:(NSMutableArray*)b toSet:(NSMutableArray*)a
{
    for (id i in b) {
        if (![self array:a containsString:i]) {
            [a addObject:i];
        }
    }
}
-(NSString*)_stateForInt:(NSUInteger)i
{
    NSString *result = @"";
    BOOL isDone = NO;
    while (!isDone) {
        NSUInteger j = i % kStateNames.length;
        result = [[kStateNames substringWithRange:NSMakeRange(j, 1)] stringByAppendingString:result];
        if (i < kStateNames.length) {
            isDone = YES;
        }
        i /= kStateNames.length;
    }
    
    return result;
}
@end
