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

A bar chart can be inverted such that it's orientation is top->down (including the selection view) by setting the following property:

	@property (nonatomic, assign, getter=isInverted) BOOL inverted;

By default, a chart's bars will be black and flat. They can be customized by supplying a UIView subclass through the <i>optional</i> protocol:

	- (UIView *)barChartView:(JBBarChartView *)barChartView barViewAtIndex:(NSUInteger)index
	{
		return ...; // color of line in chart
	}
	
If you don't require a custom UIView, simply supply a color for the bar instead:

	- (UIColor *)barChartView:(JBBarChartView *)barChartView colorForBarViewAtIndex:(NSUInteger)index;
	
If a solid color isn't your cup of tea, you can expose a gradient to be applied across the entire chart:

	- (CAGradientLayer *)barGradientForBarChartView:(JBBarChartView *)barChartView;

Furthermore, the color of the selection bar (on touch events) can be customized via the <i>optional</i> protocol:

	- (UIColor *)barSelectionColorForBarChartView:(JBBarChartView *)barChartView
	{
		return ...; // color of selection view
	}
	
<b>Note</b>: The delegate will request a custom UIView, followed by a color and lastly a gradient. If nothing is supplied, a plain black bar will be used.
	
Lastly, a bar chart's selection events are delegated back via:

	- (void)barChartView:(JBBarChartView *)barChartView didSelectBarAtIndex:(NSUInteger)index touchPoint:(CGPoint)touchPoint
	{
		// Update view
	}

	- (void)didDeselectBarChartView:(JBBarChartView *)barChartView
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
	
	- (UIColor *)lineChartView:(JBLineChartView *)lineChartView fillColorForLineAtLineIndex:(NSUInteger)lineIndex
	{
		return ...; // color of area under line in chart
	}
	
	- (CGFloat)lineChartView:(JBLineChartView *)lineChartView widthForLineAtLineIndex:(NSUInteger)lineIndex
	{
		return ...; // width of line in chart
	}
	
	- (JBLineChartViewLineStyle)lineChartView:(JBLineChartView *)lineChartView lineStyleForLineAtLineIndex:(NSUInteger)lineIndex
	{
		return ...; // style of line in chart (solid or dashed)
	}
	
Additionally, the line and fill color style can be customzized via the <i>optional</i> protocols (below). The line & fill color style apply to both selected and non-selected scenarios, meaning, if your line has a solid style, it's selected style will also be solid. 

    - (JBLineChartViewColorStyle)lineChartView:(JBLineChartView *)lineChartView colorStyleForLineAtLineIndex:(NSUInteger)lineIndex
    {
        return ...; // color line style of a line in the chart
    }
    
    - (JBLineChartViewColorStyle)lineChartView:(JBLineChartView *)lineChartView fillColorStyleForLineAtLineIndex:(NSUInteger)lineIndex
    {
        return ...; // color style for the area under a line in the chart
    }

If a solid color style is used, the following <i>optional</i> protocols can be implemented:

	- (UIColor *)lineChartView:(JBLineChartView *)lineChartView colorForLineAtLineIndex:(NSUInteger)lineIndex;
	- (UIColor *)lineChartView:(JBLineChartView *)lineChartView fillColorForLineAtLineIndex:(NSUInteger)lineIndex;
 	
Gradient color styles require a CAGradientLayer to be returned:

	- (CAGradientLayer *)lineChartView:(JBLineChartView *)lineChartView gradientForLineAtLineIndex:(NSUInteger)lineIndex;
	- (CAGradientLayer *)lineChartView:(JBLineChartView *)lineChartView fillGradientForLineAtLineIndex:(NSUInteger)lineIndex;

**Note**: gradients do not support multiple alphas. The alpha of gradient's first color be used throughout.

Defining a gradient to use is simple and flexible. For example, this would be a horizontal gradient from blue to green:

    CAGradientLayer *gradient = [CAGradientLayer new];
    gradient.startPoint = CGPointMake(0.0, 0.0);
    gradient.endPoint = CGPointMake(1.0, 0.0);
    gradient.colors = @[(id)[UIColor blueColor].CGColor, (id)[UIColor greenColor].CGColor];
    
As mentioned prior, the same color style is duplicated for selection events:

	- (UIColor *)lineChartView:(JBLineChartView *)lineChartView selectionColorForLineAtLineIndex:(NSUInteger)lineIndex;
	- (UIColor *)lineChartView:(JBLineChartView *)lineChartView selectionFillColorForLineAtLineIndex:(NSUInteger)lineIndex;

	- (CAGradientLayer *)lineChartView:(JBLineChartView *)lineChartView selectionGradientForLineAtLineIndex:(NSUInteger)lineIndex;
	- (CAGradientLayer *)lineChartView:(JBLineChartView *)lineChartView selectionFillGradientForLineAtLineIndex:(NSUInteger)lineIndex;
  
The color and width of the selection view along with the color of the selected line can be customized via the <i>optional</i> protocols:

	- (UIColor *)lineChartView:(JBLineChartView *)lineChartView verticalSelectionColorForLineAtLineIndex:(NSUInteger)lineIndex
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
	
	- (UIColor *)lineChartView:(JBLineChartView *)lineChartView selectionFillColorForLineAtLineIndex:(NSUInteger)lineIndex
	{
		return ...; // color of area under selected line
	}
	
When using a gradient for the line or fill, a different gradient can provided for selection. If the selection gradient is not provided, it will default to the line and fill gradient provided for the line.
    
    - (CAGradientLayer *)lineChartView:(JBLineChartView *)lineChartView selectionGradientForLineAtLineIndex:(NSUInteger)lineIndex
    {
        return ...; // gradient for selected line
    }

    - (CAGradientLayer *)lineChartView:(JBLineChartView *)lineChartView selectionFillGradientForLineAtLineIndex:(NSUInteger)lineIndex
    {
        return ...; // gradient for area under selected line
    }
	
By default, each line will not show dots for each point. To enable this on a per-line basis:

	- (BOOL)lineChartView:(JBLineChartView *)lineChartView showsDotsForLineAtLineIndex:(NSUInteger)lineIndex;

To the radius of each dot (default is 6x the line width, or 3x the diameter), implement:

	- (CGFloat)lineChartView:(JBLineChartView *)lineChartView dotRadiusForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex;
	
To customize the color of each dot during selection and non-selection events (default is white and black respectively), implement:

	- (UIColor *)lineChartView:(JBLineChartView *)lineChartView colorForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex;	
	- (UIColor *)lineChartView:(JBLineChartView *)lineChartView selectionColorForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex;
	
Alternatively, you can supply your own UIView instead of using the default impelmentation:

	- (UIView *)lineChartView:(JBLineChartView *)lineChartView dotViewAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex;
	
Custom dot views are automatically shown when selected unless the following is implemented:

    - (BOOL)lineChartView:(JBLineChartView *)lineChartView shouldHideDotViewOnSelectionAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex;
		
As well, by default, each line will have squared off end caps and connection points. To enable rounded connections and end caps:

	- (BOOL)lineChartView:(JBLineChartView *)lineChartView smoothLineAtLineIndex:(NSUInteger)lineIndex;
		
Furthermore, a line chart's selection events are delegated back via:

	- (void)lineChartView:(JBLineChartView *)lineChartView didSelectLineAtIndex:(NSUInteger)lineIndex horizontalIndex:(NSUInteger)horizontalIndex touchPoint:(CGPoint)touchPoint
	{
		// Update view
	}

	- (void)didDeselectLineInLineChartView:(JBLineChartView *)lineChartView
	{
		// Update view
	}
	
Upon selection, all other lines (+ fills) will be dimmed to 20% opacity (default). To change this value, implement:

    - (CGFloat)lineChartView:(JBLineChartView *)lineChartView dimmedSelectionOpacityAtLineIndex:(NSUInteger)lineIndex
    {
        // Return unselected line opacity (0.0 to hide completely, and 1.0 to have no effect)
    }

The dot selection opacity (default 0%) can also be modified via:

	- (CGFloat)lineChartView:(JBLineChartView *)lineChartView dimmedSelectionDotOpacityAtLineIndex:(NSUInteger)lineIndex
	{
		// Return unselected dot opacity (0.0 to hide completely and 1.0 to have no effect)
	}
	
If you don't want a line to be selectable:

	- (BOOL)lineChartView:(JBLineChartView *)lineChartView shouldIgnoreSelectionAtIndex:(NSUInteger)lineIndex
	{
		return NO; // Check line index
	}
	
The <b>touchPoint</b> is especially important as it allows you to add custom elements to your chart during  selection events. Refer to the demo project (<b>JBLineChartViewController</b>) to see how a tooltip can be used to display additional information during selection events.

