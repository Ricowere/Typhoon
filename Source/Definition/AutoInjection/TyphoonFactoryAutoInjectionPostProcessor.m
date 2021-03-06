////////////////////////////////////////////////////////////////////////////////
//
//  TYPHOON FRAMEWORK
//  Copyright 2013, Typhoon Framework Contributors
//  All Rights Reserved.
//
//  NOTICE: The authors permit you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

#import "TyphoonFactoryAutoInjectionPostProcessor.h"
#import "TyphoonComponentFactory.h"
#import "TyphoonDefinition.h"
#import "TyphoonDefinition+InstanceBuilder.h"
#import "NSObject+TyphoonIntrospectionUtils.h"
#import "TyphoonIntrospectionUtils.h"
#import "TyphoonTypeDescriptor.h"
#import "TyphoonInjectedObject.h"
#import "TyphoonPropertyInjection.h"
#import "TyphoonInjections.h"

static BOOL IsTyphoonAutoInjectionType(TyphoonTypeDescriptor *type);
static id TypeForInjectionFromType(TyphoonTypeDescriptor *type);

@implementation TyphoonFactoryAutoInjectionPostProcessor

- (void)postProcessDefinitionsInFactory:(TyphoonComponentFactory *)factory
{
    for (TyphoonDefinition *definition in [factory registry]) {
        [self postProcessDefinition:definition];
    }
}

- (void)postProcessDefinition:(TyphoonDefinition *)definition withFactory:(TyphoonComponentFactory *)factory
{
    [self postProcessDefinition:definition];
}

- (void)postProcessDefinition:(TyphoonDefinition *)definition
{
    Class clazz = definition.type;
    if (clazz) {
        NSArray *properties = [self autoInjectedPropertiesForClass:clazz];
        for (id<TyphoonPropertyInjection> propertyInjection in properties) {
            [definition addInjectedPropertyIfNotExists:propertyInjection];
        }
    }
}

- (NSArray *)autoInjectedPropertiesForClass:(Class)clazz
{
    NSMutableArray *injections = nil;
    NSSet *allProperties = [TyphoonIntrospectionUtils injectedPropertiesForClass:clazz upToParentClass:[NSObject class]];
    for (NSString *propertyName in allProperties) {
		TyphoonTypeDescriptor *type = [TyphoonIntrospectionUtils typeForPropertyWithName:propertyName inClass:clazz];
		
        id explicitType = TypeForInjectionFromType(type);
        if (!explicitType) {
            [NSException raise:NSInternalInconsistencyException format:@"Can't resolve '%@' property in %@ class. Make sure that specified protocol/class exist and linked.", propertyName, clazz];
        }
        id<TyphoonPropertyInjection> injection = TyphoonInjectionWithType(explicitType);
        [injection setPropertyName:propertyName];
        if (!injections) {
            injections = [[NSMutableArray alloc] initWithCapacity:allProperties.count];
        }
        [injections addObject:injection];
    }
    return injections;
}

static id TypeForInjectionFromType(TyphoonTypeDescriptor *type)
{
    if (protocol_isEqual(type.protocol, @protocol(TyphoonInjectedProtocol))) {
        return type.typeBeingDescribed;
    } else {
        return type.protocol;
    }
}

@end