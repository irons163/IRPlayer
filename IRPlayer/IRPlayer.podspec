Pod::Spec.new do |spec|
  spec.name         = "IRPlayer"
  spec.version      = "0.1.0"
  spec.summary      = "A powerful video player of iOS."
  spec.description  = "A powerful video player of iOS."
  spec.homepage     = "https://github.com/irons163/IRPlayer.git"
  spec.license      = "MIT"
  spec.author       = "irons163"
  spec.platform     = :ios, "9.0"
  spec.source       = { :git => "https://github.com/irons163/IRPlayer.git", :tag => spec.version.to_s }
  spec.source_files  = "**/*.{h,m}", "IRPlayer/**/*.{h,m}"
  spec.vendored_libraries = "**/*.a", "IRPlayer/**/*.a"
  spec.xcconfig = { "HEADER_SEARCH_PATHS" => "$(PODS_ROOT)/**/ThirdParty/ffmpeg/include" }
  spec.exclude_files = "**/ThirdParty/ffmpeg/include/**/*.h"
#  spec.header_mappings_dir  = "IRPlayer"
end
