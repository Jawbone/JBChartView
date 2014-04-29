# JBChartView
<br/>
<p align="center">	
	<img src="https://raw.github.com/Jawbone/JBChartView/master/Screenshots/main.png">
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

- Requires iOS 7 or later
- Requires Automatic Reference Counting (ARC)

## Demo

Build and run the <i>JBChartViewDemo</i> project in Xcode. The demo demonstrates the use of both the line and bar charts. It also outlines how a chart's appearance can be customized. 

## Installation

<a href="http://cocoapods.org/" target="_blank">CocoaPods</a> is the recommended method of installing JBChartView.

### The Pod Way

Simply add the following line to your <code>Podfile</code>:

	pod 'JBChartView'
	
Your Podfile should look something like:

	platform :ios, '7.0'
	pod 'JBChartView', '~> 2.4.0'
	
### The Old School Way

The simpliest way to use JBChartView with your application is to drag and drop the <i>/Classes</i> folder into you're Xcode 5 project. It's also recommended you rename the <i>/Classes</i> folder to something more descriptive (ie. "<i>Jawbone - JBChartView</i>").

<center>
	<img src="https://raw.github.com/Jawbone/JBChartView/master/Screenshots/installation.png">
</center>

## Usage

All JBChartView implementations have a similiar data source and delgate pattern to <i>UITableView</i>. If you're familiar with using a <i>UITableView</i> or <i>UITableViewController</i>, using a JBChartView subclass should be a breeze!

#### JBBarChartView

To initialize a <i>JBBarChartView</i>, you only need a few lines of code (see below). Bar charts can also be initialized via a <b>nib</b> or with a <b>frame</b>.

	JBBarChartView *barChartView = [[JBBarChartView alloc] init];
    barChartView.delegate = self;
    barChartView.dataSource = self;
    [self addSubview:barChartView];
    
At a minimum, you need to inform the data source how many bars are in the chart:

	- (NSInteger)numberOfBarsInBarChartView:(JBBarChartView *)barChartView
	{
		return ...; // number of bars in chart
	}

Secondly, you need to inform the delegate the height of each bar (automatically normalized across the entire chart):
    
    - (CGFloat)barChartView:(JBBarChartView *)barChartView heightForBarViewAtAtIndex:(NSInteger)index
    {
		return ...; // height of bar at index
	}
	
Lastly, ensure you have set the *frame* of your barChartView & call *reloadData* at least once:

	barChartView.frame = CGRectMake( ... );
	[barChartView reloadData];
    
#### JBLineChartView

Similiarily, to initialize a JBLineChartView, you only need a few lines of code (see below). Line charts can also be initialized via a <b>nib</b> or with a <b>frame</b>.

	JBLineChartView *lineChartView = [[JBLineChartView alloc] init];
    lineChartView.delegate = self;
    lineChartView.dataSource = self;
    [self addSubview:lineChartView];

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

Lastly, ensure you have set the *frame* of your lineChartView & call *reloadData* at least once:

	lineChartView.frame = CGRectMake( ... );
	[lineChartView reloadData];

	
## Customization

Both the line and bar charts support a robust set of customization options. 

The background of a bar or line chart can be set just like any other view:
	
	self.barChartView.backgroundColor = ...; // UIColor
	self.lineChartView.backgroundColor = ...; // UIColor
	
Any <i>JBChartView</i> subclass supports the use of headers and footers (similiar to that of <i>UITableView</i>):

	self.barChartView.footerView = ...; // UIView
	self.lineChartView.headerView = ...; // UIView
	
Lastly, any JBChartView subclass can be collapsed or expanded programmatically via the <i>state</i> property. If you chose to animate state changes, a callback helper can be used to notify you when the animation has completed:

	- (void)setState:(JBChartViewState)state animated:(BOOL)animated callback:(void (^)())callback;

#### JBBarChartView

By default, a chart's bars will be black and flat. They can be customized by supplying a UIView subclass through the <i>optional</i> protocol:

	- (UIView *)barChartView:(JBBarChartView *)barChartView barViewAtIndex:(NSUInteger)index
	{
		return ...; // color of line in chart
	}

Furthermore, the color of the selection bar (on touch events) can be customized via the <i>optional</i> protocol:

	- (UIColor *)barSelectionColorForBarChartView:(JBBarChartView *)barChartView
	{
		return ...; // color of selection view
	}
	
Lastly, a bar chart's selection events are delegated back via:

	- (void)barChartView:(JBBarChartView *)barChartView didSelectBarAtIndex:(NSUInteger)index touchPoint:(CGPoint)touchPoint
	{
		// Update view
	}

	- (void)didUnselectBarChartView:(JBBarChartView *)barChartView
	{
		// Update view
	}

The <b>touchPoint</b> is especially important as it allows you to add custom elements to your chart during  selection events. Refer to the demo project (<b>JBarChartViewController</b>) to see how a tooltip can be used to display additional information during selection events.

#### JBLineChartView

The color, width and style of each line in the chart can be customized via the <i>optional</i> protocol:

	- (UIColor *)lineChartView:(JBLineChartView *)lineChartView colorForLineAtLineIndex:(NSUInteger)lineIndex
	{
		return ...; // color of line in chart
	}
	
	- (CGFloat)lineChartView:(JBLineChartView *)lineChartView widthForLineAtLineIndex:(NSUInteger)lineIndex
	{
		return ...; // width of line in chart
	}
	
	- (JBLineChartViewLineStyle)lineChartView:(JBLineChartView *)lineChartView lineStyleForLineAtLineIndex:(NSUInteger)lineIndex
	{
		return ...; // style of line in chart
	}
	
Furthermore, the color and width of the selection view along with the color of the selected line can be customized via the <i>optional</i> protocols:

	- (UIColor *)verticalSelectionColorForLineChartView:(JBLineChartView *)lineChartView
	{
		return ...; // color of selection view
	}
	
	- (CGFloat)verticalSelectionWidthForLineChartView:(JBLineChartView *)lineChartView
	{
		return ...; // width of selection view
	}
	
	- (UIColor *)lineChartView:(JBLineChartView *)lineChartView selectionColorForLineAtLineIndex:(NSUInteger)lineIndex
	{
		return ...; // color of selected line
	}
	
By default, each line will not show dots for each point. To enable this on a per-line basis:

	- (BOOL)lineChartView:(JBLineChartView *)lineChartView showsDotsForLineAtLineIndex:(NSUInteger)lineIndex;

To customize the size of each dot (default 3x the line width), implement:

	- (CGFloat)lineChartView:(JBLineChartView *)lineChartView dotRadiusForLineAtLineIndex:(NSUInteger)lineIndex;
	
To customize the color of each dot during selection and non-selection events (default is white and black respectively), implement:

	- (UIColor *)lineChartView:(JBLineChartView *)lineChartView colorForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex;	

	- (UIColor *)lineChartView:(JBLineChartView *)lineChartView selectionColorForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex;
	
As well, by default, each line will have squared off end caps and connection points. To enable rounded connections and end caps:

	- (BOOL)lineChartView:(JBLineChartView *)lineChartView smoothLineAtLineIndex:(NSUInteger)lineIndex;
		
Lastly, a line chart's selection events are delegated back via:

	- (void)lineChartView:(JBLineChartView *)lineChartView didSelectLineAtIndex:(NSUInteger)lineIndex horizontalIndex:(NSUInteger)horizontalIndex touchPoint:(CGPoint)touchPoint
	{
		// Update view
	}

	- (void)didUnselectLineInLineChartView:(JBLineChartView *)lineChartView
	{
		// Update view
	}
	
The <b>touchPoint</b> is especially important as it allows you to add custom elements to your chart during  selection events. Refer to the demo project (<b>JBLineChartViewController</b>) to see how a tooltip can be used to display additional information during selection events.
	
## License

Usage is provided under the <a href="http://www.apache.org/licenses/LICENSE-2.0" target="_blank">Apache License</a> (v2.0). See <a href="https://github.com/Jawbone/JBChartView/blob/master/LICENSE">LICENSE</a> for full details.
