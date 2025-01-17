// Copyright 2024 The MediaPipe Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <Foundation/Foundation.h>
#import "MPPTaskResult.h"
#import "MPPMask.h"

NS_ASSUME_NONNULL_BEGIN

/** Represents the segmentation results generated by `ImageSegmenter`. */
NS_SWIFT_NAME(InteractiveSegmenterResult)
@interface MPPInteractiveSegmenterResult : MPPTaskResult

/**
 * An optional array of `Mask` objects. Each `Mask` in the array holds a 32 bit float array of size
 * `image width` * `image height` which represents the confidence mask for each category. Each
 * element of the float array represents the confidence with which the model predicted that the
 * corresponding pixel belongs to the category that the mask represents, usually in the range [0,1].
 */
@property(nonatomic, readonly, nullable) NSArray<MPPMask *> *confidenceMasks;

/**
 * An optional `Mask` that holds a`UInt8` array of size `image width` * `image height`. Each element
 * of this array represents the class to which the pixel in the original image was predicted to
 * belong to.
 */
@property(nonatomic, readonly, nullable) MPPMask *categoryMask;

/**
 * The quality scores of the result masks, in the range of [0, 1]. Defaults to `1` if the model
 * doesn't output quality scores. Each element corresponds to the score of the category in the model
 * outputs.
 */
@property(nonatomic, readonly, nullable) NSArray<NSNumber *> *qualityScores;

/**
 * Initializes a new `ImageSegmenterResult` with the given array of confidence masks, category mask,
 * quality scores and timestamp (in milliseconds).
 *
 * @param confidenceMasks An optional array of `Mask` objects. Each `Mask` in the array must
 * be of type `float32`.
 * @param categoryMask An optional `Mask` object of type `uInt8`.
 * @param qualityScores The quality scores of the result masks of type NSArray<NSNumber *> *. Each
 * `NSNumber` in the array holds a `float`.
 * @param timestampInMilliseconds The timestamp (in milliseconds) for this result.
 *
 * @return An instance of `ImageSegmenterResult` initialized with the given array of confidence
 * masks, category mask, quality scores and timestamp (in milliseconds).
 */
- (instancetype)initWithConfidenceMasks:(nullable NSArray<MPPMask *> *)confidenceMasks
                           categoryMask:(nullable MPPMask *)categoryMask
                          qualityScores:(nullable NSArray<NSNumber *> *)qualityScores
                timestampInMilliseconds:(NSInteger)timestampInMilliseconds;

@end

NS_ASSUME_NONNULL_END
