# JBChartView
<br/>
<p align="center">	
	<img src="https://raw.github.com/Jawbone/JBChartView/master/Screenshots/main.jpg">
</p>

Introducing <b>JBChartView - </b> Jawbone's iOS-based charting library for both line and bar graphs. It is easy to set-up, and highly customizable. 

## Features

- Drop-in UIView subclass supported across all devices.
- Line and bar graph support.
- Simple to use protocols modeled after a UITableView.
- Highly customizable.
- Expand & collapse animation support.

Refer to the <a href="https://github.com/Jawbone/JBChartView/blob/master/CHANGELOG.md"">changelog</a> for an overview of JBChartView's feature history.

## Requirements

- Requires iOS 6 or later
- Requires Automatic Reference Counting (ARC)

## Demo Project

Build and run the <i>JBChartViewDemo</i> project in Xcode. The demo demonstrates the use of both the line and bar charts. It also outlines how a chart's appearance can be customized. 

## More Demos

- <a href="https://github.com/Jawbone/anscombe-quartet-ios">Amsombe's Quartet</a>: project showcasing the use of JBChartView in the classic data visualization example known as Anscombe's Quartet.
- <a href="https://github.com/Jawbone/spark-friends-ios">Spark Friends</a>: project showcasing the use of JBChartView in the context of sparklines and (fake) user step data. 

## Installation

<a href="http://cocoapods.org/" target="_blank">CocoaPods</a> is the recommended method of installing JBChartView.

### The Pod Way

Simply add the following line to your <code>Podfile</code>:

	platform :ios, '6.0'
	pod 'JBChartView'
	
### The Old School Way

The simplest way to use JBChartView with your application is to drag and drop the <i>/Classes</i> folder into you're Xcode 5 project. It's also recommended you rename the <i>/Classes</i> folder to something more descriptive (ie. "<i>Jawbone - JBChartView</i>").

<center>
	<img src="https://raw.github.com/Jawbone/JBChartView/master/Screenshots/installation.png">
</center>

## Usage

All JBChartView implementations have a similiar data source and delgate pattern to <i>UITableView</i>. If you're familiar with using a <i>UITableView</i> or <i>UITableViewController</i>, using a JBChartView subclass should be a breeze!

#### Swift Projects

To use JBCartView in a Swift project add the following to your bridging header (JBChartView-Bridging-Header.h):

	#import <UIKit/UIKit.h>
	#import "JBChartView.h"
	#import "JBBarChartView.h"
	#import "JBLineChartView.h"

For more information about adding bridging headers see <a href="https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html" target="_blank">Swift and Objective-C in the Same Project</a>.

#### JBBarChartView

To initialize a <i>JBBarChartView</i>, you only need a few lines of code (see below). Bar charts can also be initialized via a <b>nib</b> or with a <b>frame</b>.

	JBBarChartView *barChartView = [[JBBarChartView alloc] init];
    barChartView.dataSource = self;
    barChartView.delegate = self;
    [self addSubview:barChartView];

Just like you would for a `UITableView`, ensure you clear these properties in your `dealloc`:

	- (void)dealloc
	{
		JBBarChartView *barChartView = ...; // i.e. _barChartView
		barChartView.delegate = nil;
		barChartView.dataSource = nil;
	}
    
At a minimum, you need to inform the data source how many bars are in the chart:

	- (NSUInteger)numberOfBarsInBarChartView:(JBBarChartView *)barChartView
	{
		return ...; // number of bars in chart
	}

Secondly, you need to inform the delegate the height of each bar (automatically normalized across the entire chart):
    
    - (CGFloat)barChartView:(JBBarChartView *)barChartView heightForBarViewAtIndex:(NSUInteger)index
    {
		return ...; // height of bar at index
	}
	
Lastly, ensure you have set the *frame* of your barChartView & call *reloadData* at least once:

	barChartView.frame = CGRectMake( ... );
	[barChartView reloadData];

Subsequent changes to the chart's frame will not invoke *reloadData*; it must be called directly afterwards for any changes to take effect. 
	

### Animated Reload

Both line and bar charts support *animated* reloads. The delta between the old data model and new data model is calculated and animated appropriately (ie. bars or lines will shrink, expand or morph in size). Due to techinical limitations in Apple's <a href="https://developer.apple.com/library/tvos/documentation/GraphicsImaging/Reference/CAShapeLayer_class/index.html#//apple_ref/occ/instp/CAShapeLayer/path">Quartz Core Framework</a>, line *fills* (both solid and gradient) can not be animated - they will simply 'snap' into place while the rest of the chart continues to animate.

	- (void)reloadDataAnimated:(BOOL)animated;

State changes during a reload will be ignored. As well, subsequent calls to reloadData: or reloadDataAnimated: before any previous reloads are complete, will also be ignored. Lastly, all touch events will be ignored until a reload has completed. You can always check on the state of the animation via the exposed *read-only* property: 

	@property (nonatomic, readonly) BOOL reloading;

By default, the animation will complete in approximately 0.25 seconds. The animation duration is independent from the data model size. 

**Note**: the above restrictions apply only to *animated* reloads, as non-animated reloads are synchronous.
 
#### JBLineChartView

Similiarily, to initialize a JBLineChartView, you only need a few lines of code (see below). Line charts can also be initialized via a <b>nib</b> or with a <b>frame</b>.

	JBLineChartView *lineChartView = [[JBLineChartView alloc] init];
	lineChartView.dataSource = self;
	lineChartView.delegate = self;
	[self addSubview:lineChartView];

Just like you would for a `UITableView`, ensure you clear these properties in your `dealloc`:

	- (void)dealloc
	{
		JBLineChartView *lineChartView = ...; // i.e. _lineChartView
		lineChartView.delegate = nil;
		lineChartView.dataSource = nil;
	}

At a minimum, you need to inform the data source how many lines and vertical data points (for each line) are in the chart:

	- (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView
	{
		return ...; // number of lines in chart
	}
	
	- (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex
	{
		return ...; // number of values for a line
	}

Secondly, you need to inform the delegate of the y-position of each point (automatically normalized across the entire chart) for each line in the chart:
    
    - (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex
    {
		return ...; // y-position (y-axis) of point at horizontalIndex (x-axis)
	}

**Note**: you can return NAN instead of CGFloat to indicate missing values. The chart's line will begin at the first non-NAN value and end at the last non-NAN value. The line will interopolate any NAN values in between (ie. the line will not be interrupted).

	return [[NSNumber numberWithFloat:NAN] floatValue];

Lastly, ensure you have set the *frame* of your lineChartView & call *reloadData* at least once:

	lineChartView.frame = CGRectMake( ... );
	[lineChartView reloadData];

**Note**: subsequent changes to the chart's frame will not invoke *reloadData*; it must be called directly afterwards for any changes to take effect. 
	
## Customization

Both the line and bar charts support a robust set of customization options. Read more about them <a href="Customization.md">here</a>. 

## Minimum & Maximum Values

By default, a chart's minimum and maximum values are equal to the min and max supplied by the dataSource. You can override either value via:

	- (void)setMinimumValue:(CGFloat)minimumValue;
	- (void)setMaximumValue:(CGFloat)maximumValue;

If value(s) are supplied, they must be >= 0, otherwise an assertion will be thrown. To reset the values back to their original defaults:

	- (void)resetMinimumValue;
	- (void)resetMaximumValue;
	
The min/max values are clamped to the ceiling and floor of the actual min/max values of the chart's data source; for example, if a maximumValue of 20 is supplied & the chart's actual max is 100, then 100 will be used. For min/max modifications to take effect, reloadData must be called.

## Performance

The nature of charting is to display all available information, unlike a UITableView, which can cache rows that are offscreen. JBChartView's performance will suffer if the number of data points exceed the  resolution of the device. The same issue exists with MKMapView, when hundreds of pins are supplied within a certain geographic area.  It's why Apple recommends clustering to avoid performance issues. As such, for large datasets, we recommend that your dataSource to supply a subset of points; clustering those that are close to one another. 
	
## License

Usage is provided under the <a href="http://www.apache.org/licenses/LICENSE-2.0" target="_blank">Apache License</a> (v2.0). See <a href="https://github.com/Jawbone/JBChartView/blob/master/LICENSE">LICENSE</a> for full details.
