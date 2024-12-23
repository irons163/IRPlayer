Pod::Spec.new do |spec|
    spec.name         = "IRPlayer"
    spec.version      = "0.3.7"
    spec.summary      = "A powerful video player of iOS."
    spec.description  = "A powerful video player of iOS."
    spec.homepage     = "https://github.com/irons163/IRPlayer.git"
    spec.license      = "MIT"
    spec.author       = "irons163"
    spec.platform     = :ios, "11.0"
    spec.source       = { :git => "https://github.com/irons163/IRPlayer.git", :tag => spec.version.to_s }
  
    spec.source_files  = "**/*.{h,m}"
    spec.exclude_files = "**/ThirdParty/ffmpeg/include/**/*.h", "**/ThirdParty/**/*.{h,m}"
    spec.dependency "IRFFMpeg"
    spec.pod_target_xcconfig = { "HEADER_SEARCH_PATHS" => '"$(PODS_ROOT)/IRFFMpeg/include" "$(PODS_ROOT)/IRPlayer/IRFFMpeg"',"GCC_PREPROCESSOR_DEFINITIONS" => 'IRPLATFORM_TARGET_OS_IPHONE_OR_TV IRPLATFORM_TARGET_OS_MAC_OR_IPHONE',"OTHER_LDFLAGS" => '${inherited}','ARCHS[sdk=iphonesimulator*]' => '$(ARCHS_STANDARD_64_BIT)'
    }

    spec.user_target_xcconfig = { 'VALID_ARCHS' => 'arm64 armv7' }
    spec.libraries = "z", "iconv", "bz2", "lzma"

end
