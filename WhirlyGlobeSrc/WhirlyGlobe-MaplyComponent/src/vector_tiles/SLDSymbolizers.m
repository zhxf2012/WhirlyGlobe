//
//  SLDSymbolizers.m
//  SLDTest
//
//  Created by Ranen Ghosh on 2016-08-12.
//  Copyright © 2016 mousebird consulting. All rights reserved.
//

#import "SLDSymbolizers.h"
#import "SLDWellKnownMarkers.h"

@implementation SLDSymbolizer

/** @brief Produces MaplyVectorTileStyle objects for an SLD Symbolizer element
 @details Parses the XML subtree and returns an array of corresponding MaplyVectorTileStyle objects.
 @param element The XML element corresponding to a symbolizer
 @param tileStyleSettings The base MaplyVectorStyleSettings settings to apply.
 @param viewC The map or globe view controller.
 @param minScaleDenom If non-null, the minimum map scale at which to apply any constructed symbolizer.
 @param maxScaleDenom If non-null, the maximum map scale at which to apply any constructed symbolizer.
 @return An array of MaplyVectorTileStyle objects corresponding to the particular XML element.
 @see MaplyVectorTileStyle
 @see MaplyVectorStyleSettings
 */
+ (NSArray<MaplyVectorTileStyle *> *) maplyVectorTileStyleWithElement:(DDXMLElement * _Nonnull)element tileStyleSettings:(MaplyVectorStyleSettings *)tileStyleSettings viewC:(MaplyBaseViewController *)viewC minScaleDenom:(NSNumber *)minScaleDenom maxScaleDenom:(NSNumber *)maxScaleDenom baseURL:(NSURL *)baseURL {
    
    NSString *name = [element localName];
    if ([SLDLineSymbolizer matchesSymbolizerNamed:name])
        return [SLDLineSymbolizer maplyVectorTileStyleWithElement:element tileStyleSettings:tileStyleSettings viewC:viewC minScaleDenom:minScaleDenom maxScaleDenom:maxScaleDenom baseURL:baseURL];
    else if ([SLDPolygonSymbolizer matchesSymbolizerNamed:name])
        return [SLDPolygonSymbolizer maplyVectorTileStyleWithElement:element tileStyleSettings:tileStyleSettings viewC:viewC minScaleDenom:minScaleDenom maxScaleDenom:maxScaleDenom baseURL:baseURL];
    else if ([SLDPointSymbolizer matchesSymbolizerNamed:name])
        return [SLDPointSymbolizer maplyVectorTileStyleWithElement:element tileStyleSettings:tileStyleSettings viewC:viewC minScaleDenom:minScaleDenom maxScaleDenom:maxScaleDenom baseURL:baseURL];
    else if ([SLDTextSymbolizer matchesSymbolizerNamed:name])
        return [SLDTextSymbolizer maplyVectorTileStyleWithElement:element tileStyleSettings:tileStyleSettings viewC:viewC minScaleDenom:minScaleDenom maxScaleDenom:maxScaleDenom baseURL:baseURL];
    return nil;
}

/** @brief Returns whether this class can parse the symbolizer corresponding to the provided element name.
    @details Each subclass matches different symbolizer elements.
 */
+ (BOOL)matchesSymbolizerNamed:(NSString * _Nonnull)symbolizerName {
    return NO;
}


/** @brief Gets a single node for the provided element name
 */
+ (DDXMLNode *)getSingleChildNodeForNode:(DDXMLNode *)node childName:(NSString *)childName {
    
    if (node.kind != DDXMLElementKind)
        return nil;
    DDXMLElement *element = (DDXMLElement *)node;
    NSArray *matches = [element elementsForName:childName];
    if (matches && matches.count == 1)
        return matches[0];
    return nil;
}

/** @brief If the element is an ogc:Literal, return the value.
 */
+ (NSString *)stringForLiteralInNode:(DDXMLNode *)node {
    for (DDXMLNode *child in [node children]) {
        if ([[child localName] isEqualToString:@"Literal"])
            return [child stringValue];
    }
    return nil;
}

/** @brief Get the attribute by local name (ignoring prefix)
 */
+ (DDXMLNode *)getAttributeForElement:(DDXMLElement *)element attributeName:(NSString *)attributeName {
    for (DDXMLNode *child in [element attributes]) {
        if ([[child localName] isEqualToString:attributeName])
            return child;
    }
    return nil;
}

/** @brief If the element is an ogc:Literal or ogc:PropertyName, return the appropriate value.
    @details For ogc:PropertyName, the property name is placed in square brackets for later substitution, as expected by MaplyVectorTileStyle formatText:forObject: .
    @see MaplyVectorTileStyle
 */
+ (NSString *)stringForParameterValueTypeNode:(DDXMLNode *)node {
    if ([[node localName] isEqualToString:@"PropertyName"])
        return [NSString stringWithFormat:@"[%@]", [node stringValue]];
    else if ([[node localName] isEqualToString:@"Literal"])
        return [node stringValue];
    return nil;
}

/** @brief Parses a series of se:SvgParameter child nodes and returns a dictionary.
    @details This is used to parse the style information in various elements used in symbolizers, in SLD v1.1.0.
 */
+ (NSMutableDictionary *)dictForSvgParametersInElement:(DDXMLElement *)element {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    for (DDXMLElement *paramNode in [element elementsForName:@"SvgParameter"]) {
        DDXMLNode *nameNode = [SLDSymbolizer getAttributeForElement:paramNode attributeName:@"name"];
        if (!nameNode)
            continue;
        NSString *paramName = [nameNode stringValue];
        params[paramName] = [paramNode stringValue];
    }
    if (params.count == 0)
        return nil;
    return params;
}

/** @brief Parses a series of se:CssParameter child nodes and returns a dictionary.
 @details This is used to parse the style information in various elements used in symbolizers, in SLD v1.0.0.
 */
+ (NSMutableDictionary *)dictForCssParametersInElement:(DDXMLElement *)element {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    for (DDXMLElement *paramNode in [element elementsForName:@"CssParameter"]) {
        DDXMLNode *nameNode = [SLDSymbolizer getAttributeForElement:paramNode attributeName:@"name"];
        if (!nameNode)
            continue;
        NSString *paramName = [nameNode stringValue];
        params[paramName] = [paramNode stringValue];
    }
    if (params.count == 0)
        return nil;
    return params;
}

/** @brief Parses a series of se:CssParameter or se:SvgParameter child nodes and returns a dictionary.
 @details This is used to parse the style information in various elements used in symbolizers.
 @details This will deal with both SLD versions 1.0.0 and 1.1.0.
 */
+ (NSMutableDictionary *)dictForSvgCssParametersInElement:(DDXMLElement *)element {
    NSMutableDictionary *params = [SLDSymbolizer dictForSvgParametersInElement:element];
    if (!params)
        params = [SLDSymbolizer dictForCssParametersInElement:element];
    return params;
}








+ (UIImage *)imageForHref:(NSString *)href baseURL:(NSURL *)baseURL {
    
    static NSMutableDictionary *images;
    if (!images)
        images = [NSMutableDictionary dictionary];
    
    UIImage *image = images[href];
    if (image)
        return image;
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject];
    NSURL * url = [NSURL URLWithString:href relativeToURL:baseURL];
    
    __block NSData *imageData;
    
    NSURLSessionDataTask * dataTask = [defaultSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        imageData = data;
        
        dispatch_group_leave(group);
    }];
    
    [dataTask resume];
    
    long status = dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC * 5));
    if (status != 0) {
        // timed out
        [dataTask cancel];
        NSLog(@"SLDSymbolizer imageForHref timed out.");
        return nil;
    }
    
    if (imageData)
        image = [UIImage imageWithData:imageData];
    if (image)
        images[href] = image;
    return image;
}


+ (UIImage *)imageForOnlineResourceNode:(DDXMLElement *)onlineResourceNode baseURL:(NSURL *)baseURL {
    DDXMLNode *hrefNode = [SLDSymbolizer getAttributeForElement:onlineResourceNode attributeName:@"href"];
    DDXMLNode *typeNode = [SLDSymbolizer getAttributeForElement:onlineResourceNode attributeName:@"type"];
    if (!hrefNode || (typeNode && ![[typeNode stringValue] isEqualToString:@"simple"])) {
        NSLog(@"SLDSymbolizer: Skipping unsupported graphic.");
        return nil;
    }
    
    return [SLDSymbolizer imageForHref:[hrefNode stringValue] baseURL:baseURL];
}

+ (UIImage *)imageForInlineContentNode:(DDXMLElement *)inlineContentNode {
    DDXMLNode *encodingNode = [SLDSymbolizer getAttributeForElement:inlineContentNode attributeName:@"encoding"];
    if (!encodingNode || ![[encodingNode stringValue] isEqualToString:@"base64"]) {
        NSLog(@"SLDSymbolizer: Unsupported InlineContent encoding.");
        return nil;
    }
    NSString *contents;
    for (DDXMLNode *child2 in [inlineContentNode children]) {
        if ([child2 kind] == DDXMLTextKind) {
            contents =[child2 XMLString];
            break;
        }
    }
    
    if (!contents) {
        NSLog(@"SLDSymbolizer: Failed to read InlineContent.");
        return nil;
    }
    
    NSData *imageData = [[NSData alloc] initWithBase64EncodedString:contents options:0];
    UIImage *img = [UIImage imageWithData:imageData];
    if (!img) {
        NSLog(@"SLDSymbolizer: Failed to create image with InlineContent data.");
        return nil;
    }
    
    return img;
}



@end

@implementation SLDLineSymbolizer

/** @brief See comment for SLDSymbolizer maplyVectorTileStyleWithElement:tileStyleSettings:viewC:minScaleDenom:maxScaleDenom:
 */
+ (NSArray<MaplyVectorTileStyle *> *) maplyVectorTileStyleWithElement:(DDXMLElement * _Nonnull)element tileStyleSettings:(MaplyVectorStyleSettings *)tileStyleSettings viewC:(MaplyBaseViewController *)viewC minScaleDenom:(NSNumber *)minScaleDenom maxScaleDenom:(NSNumber *)maxScaleDenom baseURL:(NSURL *)baseURL {
    
    NSLog(@"SLDLineSymbolizer flag 1");
    
    NSError *error;
    DDXMLElement *strokeNode = (DDXMLElement *)[SLDSymbolizer getSingleChildNodeForNode:element childName:@"Stroke"];
    
    if (!strokeNode)
        return nil;
    
    MaplyVectorTileStyle *s = [SLDLineSymbolizer maplyVectorTileStyleFromStrokeNode:strokeNode tileStyleSettings:tileStyleSettings viewC:viewC minScaleDenom:minScaleDenom maxScaleDenom:maxScaleDenom baseURL:baseURL];
    
    if (!s)
        return nil;
    
    NSLog(@"SLDLineSymbolizer flag 2");
    
    return @[s];
}

/** @brief See comment for SLDSymbolizer matchesSymbolizerNamed:
 */
+ (BOOL)matchesSymbolizerNamed:(NSString * _Nonnull)symbolizerName {
    return [symbolizerName isEqualToString:@"LineSymbolizer"];
}

/** @brief Parses a stroke node and returns a corresponding MaplyVectorTileStyle object.
 */
+ (MaplyVectorTileStyle *)maplyVectorTileStyleFromStrokeNode:(DDXMLElement *)strokeNode tileStyleSettings:(MaplyVectorStyleSettings *)tileStyleSettings viewC:(MaplyBaseViewController *)viewC minScaleDenom:(NSNumber *)minScaleDenom maxScaleDenom:(NSNumber *)maxScaleDenom baseURL:(NSURL *)baseURL {
    
    NSMutableDictionary *strokeParams = [SLDSymbolizer dictForSvgCssParametersInElement:strokeNode];
    if (!strokeParams) {
        NSLog(@"SLDLineSymbolizer: Stroke node without stroke parameters.");
        return nil;
    }
    
    if (minScaleDenom)
        strokeParams[@"minscaledenom"] = minScaleDenom;
    if (maxScaleDenom)
        strokeParams[@"maxscaledenom"] = maxScaleDenom;
    
    MaplyVectorTileStyle *s = [MaplyVectorTileStyle styleFromStyleEntry:@{@"type": @"LineSymbolizer", @"substyles": @[strokeParams]}
                                                               settings:tileStyleSettings
                                                                  viewC:viewC];
    return s;
}

@end

@implementation SLDPolygonSymbolizer

/** @brief See comment for SLDSymbolizer matchesSymbolizerNamed:
 */
+ (BOOL)matchesSymbolizerNamed:(NSString * _Nonnull)symbolizerName {
    return [symbolizerName isEqualToString:@"PolygonSymbolizer"];
}

/** @brief See comment for SLDSymbolizer maplyVectorTileStyleWithElement:tileStyleSettings:viewC:minScaleDenom:maxScaleDenom:
 */
+ (NSArray<MaplyVectorTileStyle *> *) maplyVectorTileStyleWithElement:(DDXMLElement * _Nonnull)element tileStyleSettings:(MaplyVectorStyleSettings *)tileStyleSettings viewC:(MaplyBaseViewController *)viewC minScaleDenom:(NSNumber *)minScaleDenom maxScaleDenom:(NSNumber *)maxScaleDenom baseURL:(NSURL *)baseURL {
    
    NSLog(@"SLDPolygonSymbolizer flag 1");
    
    NSError *error;
    DDXMLElement *fillNode = (DDXMLElement *)[SLDSymbolizer getSingleChildNodeForNode:element childName:@"Fill"];
    DDXMLElement *strokeNode = (DDXMLElement *)[SLDSymbolizer getSingleChildNodeForNode:element childName:@"Stroke"];
   
    NSMutableArray <MaplyVectorTileStyle *> *styles = [NSMutableArray array];
    if (strokeNode) {
        MaplyVectorTileStyle *style = [SLDLineSymbolizer maplyVectorTileStyleFromStrokeNode:strokeNode tileStyleSettings:tileStyleSettings viewC:viewC minScaleDenom:minScaleDenom maxScaleDenom:maxScaleDenom baseURL:baseURL];
        if (style)
            [styles addObject:style];
    }
    
    if (fillNode) {
        MaplyVectorTileStyle *style = [SLDPolygonSymbolizer maplyVectorTileStyleFromFillNode:fillNode tileStyleSettings:tileStyleSettings viewC:viewC minScaleDenom:minScaleDenom maxScaleDenom:maxScaleDenom baseURL:baseURL];
        if (style)
            [styles addObject:style];
    }
    
    NSLog(@"SLDPolygonSymbolizer flag 2");

    if (styles.count > 0)
        return styles;

    return nil;
}

/** @brief Parses a fill node and returns a corresponding MaplyVectorTileStyle object.
 */
+ (MaplyVectorTileStyle *)maplyVectorTileStyleFromFillNode:(DDXMLElement *)fillNode tileStyleSettings:(MaplyVectorStyleSettings *)tileStyleSettings viewC:(MaplyBaseViewController *)viewC minScaleDenom:(NSNumber *)minScaleDenom maxScaleDenom:(NSNumber *)maxScaleDenom baseURL:(NSURL *)baseURL {
    
    NSMutableDictionary *fillParams = [SLDSymbolizer dictForSvgCssParametersInElement:fillNode];
    if (!fillParams) {
        NSLog(@"SLDPolygonSymbolizer: Fill node but no fill parameters.");
        return nil;
    }
    
    if (minScaleDenom)
        fillParams[@"minscaledenom"] = minScaleDenom;
    if (maxScaleDenom)
        fillParams[@"maxscaledenom"] = maxScaleDenom;
    
    MaplyVectorTileStyle *s = [MaplyVectorTileStyle styleFromStyleEntry:@{@"type": @"PolygonSymbolizer", @"substyles": @[fillParams]}
                                                               settings:tileStyleSettings
                                                                  viewC:viewC];
    return s;
}


@end

@implementation SLDPointSymbolizer

/** @brief See comment for SLDSymbolizer matchesSymbolizerNamed:
 */
+ (BOOL)matchesSymbolizerNamed:(NSString * _Nonnull)symbolizerName {
    return [symbolizerName isEqualToString:@"PointSymbolizer"];
}

/** @brief See comment for SLDSymbolizer maplyVectorTileStyleWithElement:tileStyleSettings:viewC:minScaleDenom:maxScaleDenom:
 */
+ (NSArray<MaplyVectorTileStyle *> *) maplyVectorTileStyleWithElement:(DDXMLElement * _Nonnull)element tileStyleSettings:(MaplyVectorStyleSettings *)tileStyleSettings viewC:(MaplyBaseViewController *)viewC minScaleDenom:(NSNumber *)minScaleDenom maxScaleDenom:(NSNumber *)maxScaleDenom baseURL:(NSURL *)baseURL {
    
    MaplyVectorTileStyle *s = [SLDPointSymbolizer maplyVectorTileStyleFromPointSymbolizerNode:element tileStyleSettings:tileStyleSettings viewC:viewC minScaleDenom:minScaleDenom maxScaleDenom:maxScaleDenom baseURL:baseURL];
    
    if (!s)
        return nil;
    
    return @[s];
}

/** @brief Parses a PointSymbolizer node and returns a corresponding MaplyVectorTileStyle object.
 */
+ (MaplyVectorTileStyle *)maplyVectorTileStyleFromPointSymbolizerNode:(DDXMLElement *)pointSymbolizerNode tileStyleSettings:(MaplyVectorStyleSettings *)tileStyleSettings viewC:(MaplyBaseViewController *)viewC minScaleDenom:(NSNumber *)minScaleDenom maxScaleDenom:(NSNumber *)maxScaleDenom baseURL:(NSURL *)baseURL {
    
    NSError *error;
    NSMutableDictionary *pointParams = [NSMutableDictionary dictionary];

    DDXMLElement *graphicNode = (DDXMLElement *)[SLDSymbolizer getSingleChildNodeForNode:pointSymbolizerNode childName:@"Graphic"];
    
    if (!graphicNode)
        return nil;
    
    for (DDXMLNode *child in [graphicNode children]) {
        NSString *childName = [child localName];
        
        if ([childName isEqualToString:@"ExternalGraphic"]) {
        
            DDXMLElement *onlineResourceNode = (DDXMLElement *)[SLDSymbolizer getSingleChildNodeForNode:child childName:@"OnlineResource"];
            DDXMLElement *inlineContentNode = (DDXMLElement *)[SLDSymbolizer getSingleChildNodeForNode:child childName:@"InlineContent"];
            DDXMLElement *formatNode = (DDXMLElement *)[SLDSymbolizer getSingleChildNodeForNode:child childName:@"Format"];
            
            NSString *format = (formatNode ? [formatNode stringValue] : nil);
            if (!format || (![format isEqualToString:@"image/png"] && ![format isEqualToString:@"image/gif"])) {
                NSLog(@"SLDPointSymbolizer: Skipping unsupported graphic format.");
                return nil;
            }
            
            if (onlineResourceNode) {
                UIImage *image = [SLDSymbolizer imageForOnlineResourceNode:onlineResourceNode baseURL:baseURL];
                if (image)
                    pointParams[@"image"] = image;
            } else if (inlineContentNode) {
                UIImage *image = [SLDSymbolizer imageForInlineContentNode:inlineContentNode];
                if (image)
                    pointParams[@"image"] = image;
            } else {
                NSLog(@"SLDPointSymbolizer: Unexpected ExternalGraphic structure.");
                return nil;
            }
            
        } else if ([childName isEqualToString:@"Mark"]) {
            
            DDXMLElement *wellKnownNameNode = (DDXMLElement *)[SLDSymbolizer getSingleChildNodeForNode:child childName:@"WellKnownName"];
            DDXMLElement *onlineResourceNode = (DDXMLElement *)[SLDSymbolizer getSingleChildNodeForNode:child childName:@"OnlineResource"];
            DDXMLElement *inlineContentNode = (DDXMLElement *)[SLDSymbolizer getSingleChildNodeForNode:child childName:@"InlineContent"];
            DDXMLElement *formatNode = (DDXMLElement *)[SLDSymbolizer getSingleChildNodeForNode:child childName:@"Format"];
            
            if (wellKnownNameNode) {
            
                NSString *wellKnownName = [wellKnownNameNode stringValue];
                
                UIImage *image;
                if ([wellKnownName isEqualToString:@"square"])
                    image = [SLDWellKnownMarkers squareImage];
                else if ([wellKnownName isEqualToString:@"circle"])
                    image = [SLDWellKnownMarkers circleImage];
                else if ([wellKnownName isEqualToString:@"triangle"])
                    image = [SLDWellKnownMarkers triangleImage];
                else if ([wellKnownName isEqualToString:@"star"])
                    image = [SLDWellKnownMarkers starImage];
                else if ([wellKnownName isEqualToString:@"cross"])
                    image = [SLDWellKnownMarkers crossImage];
                else if ([wellKnownName isEqualToString:@"x"])
                    image = [SLDWellKnownMarkers xImage];
                else {
                    NSLog(@"Skipping MarkerSymbolizer with unrecognized WellKnownName for Mark.");
                    return nil;
                }
                pointParams[@"image"] = image;
                
            } else {
                
                NSString *format = (formatNode ? [formatNode stringValue] : nil);
                if (!format || (![format isEqualToString:@"image/png"] && ![format isEqualToString:@"image/gif"])) {
                    NSLog(@"SLDPointSymbolizer: Skipping unsupported graphic format.");
                    return nil;
                }
                
                if (onlineResourceNode) {
                    UIImage *image = [SLDSymbolizer imageForOnlineResourceNode:onlineResourceNode baseURL:baseURL];
                    if (image)
                        pointParams[@"image"] = image;
                } else if (inlineContentNode) {
                    UIImage *image = [SLDSymbolizer imageForInlineContentNode:inlineContentNode];
                    if (image)
                        pointParams[@"image"] = image;
                } else {
                    NSLog(@"SLDPointSymbolizer: Unexpected Makr structure.");
                    return nil;
                }
            }
            
            // Fill color
            DDXMLElement *fillNode = (DDXMLElement *)[SLDSymbolizer getSingleChildNodeForNode:child childName:@"Fill"];
            if (fillNode) {
                NSDictionary *fillParams = [SLDSymbolizer dictForSvgCssParametersInElement:fillNode];
                
                if (fillParams && fillParams[@"fill"])
                    pointParams[@"fill"] = fillParams[@"fill"];
            }
            
            // Stroke color
            DDXMLElement *strokeNode = (DDXMLElement *)[SLDSymbolizer getSingleChildNodeForNode:child childName:@"Stroke"];
            if (strokeNode) {
                NSDictionary *strokeParams = [SLDSymbolizer dictForSvgCssParametersInElement:strokeNode];
                
                if (strokeParams && strokeParams[@"stroke"])
                    pointParams[@"stroke"] = strokeParams[@"stroke"];
            }

            
        } else if ([childName isEqualToString:@"Size"]) {
            // Marker size
            NSString *size = [SLDSymbolizer stringForLiteralInNode:child];
            if (size) {
                pointParams[@"width"] = size;
                pointParams[@"height"] = size;
            }
        }
    }
    
    if (minScaleDenom)
        pointParams[@"minscaledenom"] = minScaleDenom;
    if (maxScaleDenom)
        pointParams[@"maxscaledenom"] = maxScaleDenom;
    
    MaplyVectorTileStyle *s = [MaplyVectorTileStyle styleFromStyleEntry:@{@"type": @"MarkersSymbolizer", @"substyles": @[pointParams]}
                                                               settings:tileStyleSettings
                                                                  viewC:viewC];
    return s;
}

@end

@implementation SLDTextSymbolizer

/** @brief See comment for SLDSymbolizer matchesSymbolizerNamed:
 */
+ (BOOL)matchesSymbolizerNamed:(NSString * _Nonnull)symbolizerName {
    return [symbolizerName isEqualToString:@"TextSymbolizer"];
}

/** @brief See comment for SLDSymbolizer maplyVectorTileStyleWithElement:tileStyleSettings:viewC:minScaleDenom:maxScaleDenom:
 */
+ (NSArray<MaplyVectorTileStyle *> *) maplyVectorTileStyleWithElement:(DDXMLElement * _Nonnull)element tileStyleSettings:(MaplyVectorStyleSettings *)tileStyleSettings viewC:(MaplyBaseViewController *)viewC minScaleDenom:(NSNumber *)minScaleDenom maxScaleDenom:(NSNumber *)maxScaleDenom baseURL:(NSURL *)baseURL {
    
    MaplyVectorTileStyle *s = [SLDTextSymbolizer maplyVectorTileStyleFromTextSymbolizerNode:element tileStyleSettings:tileStyleSettings viewC:viewC minScaleDenom:minScaleDenom maxScaleDenom:maxScaleDenom baseURL:baseURL];
    
    if (!s)
        return nil;
    
    return @[s];
}

/** @brief Parses a TextSymbolizer node and returns a corresponding MaplyVectorTileStyle object.
 */
+ (MaplyVectorTileStyle *)maplyVectorTileStyleFromTextSymbolizerNode:(DDXMLElement *)textSymbolizerNode tileStyleSettings:(MaplyVectorStyleSettings *)tileStyleSettings viewC:(MaplyBaseViewController *)viewC minScaleDenom:(NSNumber *)minScaleDenom maxScaleDenom:(NSNumber *)maxScaleDenom baseURL:(NSURL *)baseURL {
    
    NSError *error;
    NSMutableDictionary *labelParams = [NSMutableDictionary dictionary];
    
    // Label text
    DDXMLElement *labelNode = (DDXMLElement *)[SLDSymbolizer getSingleChildNodeForNode:textSymbolizerNode childName:@"Label"];
    if (labelNode) {
        for (DDXMLNode *child in [labelNode children]) {
            NSString *value = [SLDSymbolizer stringForParameterValueTypeNode:child];
            if (value) {
                labelParams[@"value"] = value;
                break;
            }
        }
    }
    
    // Ignore specified font for now.
    DDXMLElement *fontNode = (DDXMLElement *)[SLDSymbolizer getSingleChildNodeForNode:textSymbolizerNode childName:@"Font"];
    

    // Label placement
    DDXMLElement *labelPlacementNode = (DDXMLElement *)[SLDSymbolizer getSingleChildNodeForNode:textSymbolizerNode childName:@"LabelPlacement"];
    if (labelPlacementNode) {
        DDXMLElement *pointPlacementNode = (DDXMLElement *)[SLDSymbolizer getSingleChildNodeForNode:labelPlacementNode childName:@"PointPlacement"];
        DDXMLElement *linePlacementNode = (DDXMLElement *)[SLDSymbolizer getSingleChildNodeForNode:labelPlacementNode childName:@"LinePlacement"];
        
        if (pointPlacementNode)
            labelParams[@"placement"] = @"point";
        else if (linePlacementNode)
            labelParams[@"placement"] = @"line";
    }
    
    
    // Label halo
    DDXMLElement *haloNode = (DDXMLElement *)[SLDSymbolizer getSingleChildNodeForNode:textSymbolizerNode childName:@"Halo"];
    if (haloNode) {
        DDXMLElement *haloRadiusNode = (DDXMLElement *)[SLDSymbolizer getSingleChildNodeForNode:haloNode childName:@"Radius"];
        DDXMLElement *haloFillNode = (DDXMLElement *)[SLDSymbolizer getSingleChildNodeForNode:haloNode childName:@"Fill"];
        
        if (haloRadiusNode) {
            NSString *haloRadius = [SLDSymbolizer stringForLiteralInNode:haloRadiusNode];
            if (haloRadius)
                labelParams[@"halo-radius"] = haloRadius;
        }
        if (haloFillNode) {
            
            NSDictionary *haloFillParams = [SLDSymbolizer dictForSvgCssParametersInElement:haloFillNode];
            if (haloFillParams && haloFillParams[@"fill"])
                labelParams[@"halo-fill"] = haloFillParams[@"fill"];
        }
    }
    
    // Label fill
    DDXMLElement *fillNode = (DDXMLElement *)[SLDSymbolizer getSingleChildNodeForNode:textSymbolizerNode childName:@"Fill"];
    if (fillNode) {
        
        NSDictionary *labelFillParams = [SLDSymbolizer dictForSvgCssParametersInElement:fillNode];
        if (labelFillParams && labelFillParams[@"fill"])
            labelParams[@"fill"] = labelFillParams[@"fill"];
        if (labelFillParams && labelFillParams[@"fill-opacity"])
            labelParams[@"opacity"] = labelFillParams[@"fill-opacity"];
    }

    if (minScaleDenom)
        labelParams[@"minscaledenom"] = minScaleDenom;
    if (maxScaleDenom)
        labelParams[@"maxscaledenom"] = maxScaleDenom;
    
    labelParams[@"dx"] = @(25);
    
    MaplyVectorTileStyle *s = [MaplyVectorTileStyle styleFromStyleEntry:@{@"type": @"TextSymbolizer", @"substyles": @[labelParams]}
                                                               settings:tileStyleSettings
                                                                  viewC:viewC];
    return s;
}

@end








