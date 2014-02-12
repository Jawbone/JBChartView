# JBChartView

<center>
	<img src="https://raw.github.com/Jawbone/JBChartView/master/Screenshots/main.png">
</center>

<b>Introducing JBChartView - </b> Jawbone's iOS-based charting library for both line and bar graphs. It is easy to set-up, and highly customizable. 

## Features

- Drop-in UIView subclass supported across all devices.
- Line and bar graph support.
- Simple to use protocols modeled after a UITableView.
- Highly customizable.
- Expand & collapse animation support.

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
	pod 'JBChartView', '~> 1.1.5'
	
### The Old School Way

The simpliest way to use JBChartView with your application is to drag and drop the <i>/Classes</i> folder into you're Xcode 5 project. It's also recommended you rename the <i>/Classes</i> folder to something more descriptive (ie. "<i>Jawbone - JBChartView</i>").

<center>
	<img src="https://raw.github.com/Jawbone/JBChartView/master/Screenshots/installation.png">
</center>

## Usage

Both JBChartView implementations have a similiar data source and delgate pattern to <i>UITableView</i>. If you're familiar with using a <i>UITableView</i> or <i>UITableViewController</i>, using a JBChartView subclass should be a breeze!

#### JBBarChartView

To initialize a <i>JBBarChartView</i>, you only need a few lines of code:

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
    
#### JBLineChartView

Similiarily, to initialize a JBLineChartView, you only need a few lines of code:

	JBLineChartView *lineChartView = [[JBLineChartView alloc] init];
    lineChartView.delegate = self;
    lineChartView.dataSource = self;
    [self addSubview:lineChartView];

At a minimum, you need to inform the data source how many points are in the line chart:

	- (NSInteger)numberOfPointsInLineChartView:(JBLineChartView *)lineChartView
	{
		return ...; // number of points in chart
	}

Secondly, you need to inform the delegate the y-position of each point (automatically normalized across the entire chart):
    
	- (CGFloat)lineChartView:(JBLineChartView *)lineChartView heightForIndex:(NSInteger)index
    {
		return ...; // y-position of poinnt at index (x-axis)
	}
	
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

	- (UIView *)barViewForBarChartView:(JBBarChartView *)barChartView atIndex:(NSInteger)index
	{
		return ...; // color of line in chart
	}

Furthermore, the color of the selection bar (on touch events) can be customized via the <i>optional</i> protocol:

	- (UIColor *)selectionBarColorForBarChartView:(JBBarChartView *)barChartView
	{
		return ...; // color of selection view
	}
	
Lastly, a bar chart's selection events are delegated back via:

	- (void)barChartView:(JBBarChartView *)barChartView didSelectBarAtIndex:(NSInteger)index
	{
		// Update view
	}

	- (void)barChartView:(JBBarChartView *)barChartView didUnselectBarAtIndex:(NSInteger)index
	{
		// Update view
	}
	
A JBBarChartView visuaul overview can be found <a href="https://raw.github.com/Jawbone/JBChartView/master/Screenshots/JBBarChartView.png" target="_blank">here</a>. 

#### JBLineChartView

The color of the chart's line can be customized via the <i>optional</i> protocol:

	- (UIColor *)lineColorForLineChartView:(JBLineChartView *)lineChartView
	{
		return ...; // color of line in chart
	}
	
Furthermore, the color of the selection bar (on touch events) can be customized via the <i>optional</i> protocol:

	- (UIColor *)selectionColorForLineChartView:(JBLineChartView *)lineChartView
	{
		return ...; // color of selection view
	}
	
Lastly, a line chart's selection events are delegated back via:

	- (void)lineChartView:(JBLineChartView *)lineChartView didSelectChartAtIndex:(NSInteger)index
	{
		// Update view
	}

	- (void)lineChartView:(JBLineChartView *)lineChartView didUnselectChartAtIndex:(NSInteger)index
	{
		// Update view
	}
			
A JBLineChartView visuaul overview can be found <a href="https://raw.github.com/Jawbone/JBChartView/master/Screenshots/JBLineChartView.png" target="_blank">here</a>.
	
## License

Usage is provided under the <a href="http://www.apache.org/licenses/LICENSE-2.0" target="_blank">Apache License</a> (v2.0). See <a href="https://github.com/Jawbone/JBChartView/blob/master/LICENSE">LICENSE</a> for full details.
