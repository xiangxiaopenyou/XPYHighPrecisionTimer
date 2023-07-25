Pod::Spec.new do |s|
  s.name         = "XPYHighPrecisionTimer"
  s.version      = "1.0.0"
  s.license         = 'MIT'
  s.summary      = "Timer"
  s.description  = "A high-precision timer."
  s.homepage     = "https://github.com/xiangxiaopenyou"
  s.author   = { 'xxpy' => 'xlpioser@163.com' }
  s.platform     = :ios, "9.0"
  s.source   = { "http": "git@github.com:xiangxiaopenyou/XPYHighPrecisionTimer.git"}
  s.source_files = 'XPYHighPrecisionTimer/*.{h,m}'
end
