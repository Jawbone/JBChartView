Pod::Spec.new do |s|
  s.name         = "JBChartView"
  s.version      = "2.7.3"
  s.summary      = "Jawbone's iOS-based charting library for both line and bar graphs."
  s.homepage     = "https://github.com/Jawbone/JBChartView"

  s.screenshot   = "https://raw.github.com/Jawbone/JBChartView/master/Screenshots/main.jpg"

  s.license      = { :type => 'Apache', :file => 'LICENSE' }
  s.author       = { "Terry Worona" => "tworona@jawbone.com" }
  s.source       = { 
	:git => "https://github.com/Jawbone/JBChartView.git",
	:tag => "v2.7.3"
  }

  s.platform     = :ios, '6.0'
  s.source_files = 'Classes/**/*.{h,m}'
  s.requires_arc = true
end
