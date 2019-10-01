Pod::Spec.new do |spec|
  spec.name         = "IRPlayer"
  spec.version      = "0.3.0"
  spec.summary      = "A powerful video player of iOS."
  spec.description  = "A powerful video player of iOS."
  spec.homepage     = "https://github.com/irons163/IRPlayer.git"
  spec.license      = "MIT"
  spec.author       = "irons163"
  spec.platform     = :ios, "11.0"
  spec.source       = { :git => "https://github.com/irons163/IRFFMpeg.git" }
  spec.source       = { :git => "https://github.com/irons163/IRPlayer.git", :tag => "0.1.1" }
  
#  spec.source_files  = "IRPlayer/**/*.{h,m}"
#  spec.exclude_files = "**/ThirdParty/ffmpeg/include/**/*.h"
##  spec.vendored_frameworks = "IRFFMpeg"
#  spec.dependency "IRFFMpeg"
#  spec.static_framework = true

  spec.source_files  = "IRPlayer/Class/**/*.{h,m}", "IRPlayer/*.{h,m}"
#  spec.header_mappings_dir = ""
#  spec.vendored_libraries = "**/*.a", "IRPlayer/**/*.a"
#spec.xcconfig = { "HEADER_SEARCH_PATHS" => "$(PODS_ROOT)/IRPlayer/ThirdParty/ffmpeg/include",
#  "USER_HEADER_SEARCH_PATHS" => "$(PODS_ROOT)/IRPlayer/ThirdParty/ffmpeg/include"
#}
#  spec.public_header_files = "IRPlayer/**/Class/**/*.h"
#  spec.header_mappings_dir = "IRPlayer"
#$dir = File.dirname(__FILE__)
#$dir = $dir + "/IRPlayer/ThirdParty/ffmpeg/include"  #$dir:/Users/wangbing/TempCode/MyLibrary/cfiles/**
#spec.xcconfig = { "HEADER_SEARCH_PATHS" => '${dir}'}

#  spec.xcconfig = { "HEADER_SEARCH_PATHS" => '"$(SRCROOT)/IRPlayer/ThirdParty/ffmpeg/include" "$(PODS_ROOT)/IRPlayer/FFMpegLib" "${PODS_ROOT}/Headers/Private" "${PODS_ROOT}/Headers/Private/IRPlayer/FFMpegLib" "${PODS_ROOT}/Headers/Public" "${PODS_ROOT}/Headers/Public/IRPlayer/FFMpegLib"',
#    "USER_HEADER_SEARCH_PATHS" => '"$(PODS_ROOT)/IRPlayer/FFMpegLib" "${PODS_ROOT}/Headers/Private" "${PODS_ROOT}/Headers/Private/IRPlayer/FFMpegLib" "${PODS_ROOT}/Headers/Public" "${PODS_ROOT}/Headers/Public/IRPlayer/FFMpegLib"'
#  }
spec.pod_target_xcconfig = { "HEADER_SEARCH_PATHS" => '"$(PODS_TARGET_SRCROOT)/IRPlayer/ThirdParty/ffmpeg/include" "$(PODS_TARGET_SRCROOT)/IRPlayer/ThirdParty/ffmpeg/include/libavfilter" "$(PODS_TARGET_SRCROOT)/IRPlayer/ThirdParty/ffmpeg/include/libavutil" "$(PODS_TARGET_SRCROOT)/IRPlayer/ThirdParty/ffmpeg/include/libavdevice" "$(PODS_TARGET_SRCROOT)/IRPlayer/ThirdParty/ffmpeg/include/libavformat" "$(PODS_TARGET_SRCROOT)/IRPlayer/ThirdParty/ffmpeg/include/libswscale" "$(PODS_TARGET_SRCROOT)/IRPlayer/ThirdParty/ffmpeg/include/libavcodec" "$(PODS_TARGET_SRCROOT)/IRPlayer/ThirdParty/ffmpeg/include/libswresample" "$(PODS_ROOT)/IRPlayer/FFMpegLib" "${PODS_ROOT}/Headers/Private" "${PODS_ROOT}/Headers/Private/IRPlayer/FFMpegLib" "${PODS_ROOT}/Headers/Public" "${PODS_ROOT}/Headers/Public/IRPlayer/FFMpegLib" "${PODS_ROOT}/Headers"',
  "USER_HEADER_SEARCH_PATHS" => '"$(PODS_TARGET_SRCROOT)/IRPlayer/ThirdParty/ffmpeg/include" "$(PODS_ROOT)/IRPlayer/FFMpegLib" "${PODS_ROOT}/Headers/Private" "${PODS_ROOT}/Headers/Private/IRPlayer/FFMpegLib" "${PODS_ROOT}/Headers/Public" "${PODS_ROOT}/Headers/Public/IRPlayer/FFMpegLib"',
  "GCC_PREPROCESSOR_DEFINITIONS" => 'IRPLATFORM_TARGET_OS_IPHONE_OR_TV IRPLATFORM_TARGET_OS_MAC_OR_IPHONE',
  "OTHER_LDFLAGS" => '${inherited}',
  'ARCHS[sdk=iphonesimulator*]' => '$(ARCHS_STANDARD_64_BIT)'
}
spec.user_target_xcconfig = { 'VALID_ARCHS' => 'arm64 armv7' }
#  spec.xcconfig = { "HEADER_SEARCH_PATHS" => "**/ThirdParty/ffmpeg/include", "USER_HEADER_SEARCH_PATHS" => "**/ThirdParty/ffmpeg/include" }
#spec.xcconfig = { "HEADER_SEARCH_PATHS" => '"$(PODS_ROOT)/IRPlayer/ThirdParty/ffmpeg/include" "$(PODS_ROOT)/Headers/Public/IRPlayer/ThirdParty/ffmpeg"/**' }
#  spec.exclude_files = "**/ThirdParty/ffmpeg/include/**/version.h"
#spec.source_files  = "IRPlayer/**/*.{h,m}"
#spec.exclude_files = "**/ThirdParty/ffmpeg/include/**/*.h"
spec.preserve_paths = "IRPlayer/ThirdParty/ffmpeg/include/libavfilter/**/*", "IRPlayer/ThirdParty/ffmpeg/include/libavutil/**/*", "IRPlayer/ThirdParty/ffmpeg/include/libavdevice/**/*", "IRPlayer/ThirdParty/ffmpeg/include/libavformat/**/*", "IRPlayer/ThirdParty/ffmpeg/include/libswscale/**/*", "IRPlayer/ThirdParty/ffmpeg/include/libavcodec/**/*", "IRPlayer/ThirdParty/ffmpeg/include/libswresample/**/*"
#spec.header_mappings_dir  = "."

#  spec.subspec 'ImpPublic' do |subcfiles|
#    subcfiles.source_files  = "IRPlayer/Class/Platform/**/*.{h,m}"
##    subcfiles.dependency "#{spec.name}/Implementation"
#    subcfiles.header_mappings_dir  = "."
#  end
#
#  spec.subspec 'Implementation' do |subcfiles|
#    subcfiles.source_files  = "IRPlayer/Class/*.{h,m}", "IRPlayer/*.{h,m}", "IRPlayer/Class/Core/**/*.{h,m}"
#    subcfiles.exclude_files = "**/ThirdParty/ffmpeg/include/**/*.h"
#    subcfiles.dependency "#{spec.name}/FFMpegLib"
#    subcfiles.dependency "#{spec.name}/ImpPublic"
#    subcfiles.header_mappings_dir  = "."
##    subcfiles.private_header_files = 'IRPlayer/Class/Core/**/*.h', 'IRPlayer/Class/Platform/**/*.h'
##    subcfiles.pod_target_xcconfig = { "HEADER_SEARCH_PATHS" => '"$(PODS_TARGET_SRCROOT)/IRPlayer/ThirdParty/ffmpeg/include" "$(PODS_ROOT)/IRPlayer/FFMpegLib" "${PODS_ROOT}/Headers/Private" "${PODS_ROOT}/Headers/Private/IRPlayer/FFMpegLib" "${PODS_ROOT}/Headers/Public" "${PODS_ROOT}/Headers/Public/IRPlayer/FFMpegLib" "${PODS_ROOT}/Headers"',
##      "USER_HEADER_SEARCH_PATHS" => '"$(PODS_TARGET_SRCROOT)/IRPlayer/ThirdParty/ffmpeg/include" "$(PODS_ROOT)/IRPlayer/FFMpegLib" "${PODS_ROOT}/Headers/Private" "${PODS_ROOT}/Headers/Private/IRPlayer/FFMpegLib" "${PODS_ROOT}/Headers/Public" "${PODS_ROOT}/Headers/Public/IRPlayer/FFMpegLib"',
##      "GCC_PREPROCESSOR_DEFINITIONS" => 'IRPLATFORM_TARGET_OS_IPHONE_OR_TV IRPLATFORM_TARGET_OS_MAC_OR_IPHONE',
##      "OTHER_LDFLAGS" => '${inherited}',
##      'ARCHS[sdk=iphonesimulator*]' => '$(ARCHS_STANDARD_64_BIT)'
##    }
#  end

  spec.subspec 'FFMpegLib' do |subcfiles|

    #subspec包含的代码文件，上面source是路径，这里source_files是具体要包含哪些文件
    #其中**表示包含子目录，*表示当前目录下的所有文件
    #下面表示当前subspec包含MyLibrary/cfiles目录及其子目录中的所有.h和.c文件；以及MyLibrary/log目录下的所有.h和.c文件
#    subcfiles.source_files = "IRPlayer/ThirdParty/ffmpeg/include/**/*.h"
    subcfiles.preserve_paths = "IRPlayer/ThirdParty/ffmpeg/include/**/*"
    #不包含的文件
#    subcfiles.exclude_files = "**/ThirdParty/ffmpeg/include/**/version.h"

    #加入到pod库中，被一起编译
    #这里通常使用私有第三方库时，需要依赖某个lib或framework时使用。
    #添加如下选项后，会将.a添加到工程中，并且添加LIBRARY_SEARCH_PATHS路径
    #但是需要注意的是，如果使用pod package对该pod库进行打包，这个.a并不会打进去。
    #比如说使用pod package对MyLibrary打包成MyLibrary.a，inner.a并不会被编译进MyLibrary.a。
    #此时，如果如果对外提供MyLibrary.a，inner.a也同样需要提供出去
#    subcfiles.vendored_libraries = "MyLibrary/lib/ios/inner.a"
    subcfiles.vendored_libraries = "IRPlayer/**/ThirdParty/ffmpeg/**/*.a"
    subcfiles.libraries = "z", "iconv", "bz2", "lzma"
    subcfiles.frameworks = "AVFoundation"
#    subcfiles.public_header_files = "**/ThirdParty/ffmpeg/include/**/*.h"
    #pod工程的配置
    #对于HEADER_SEARCH_PATHS，对将设置的字符串直接拷贝到xcode中，不会像上面source_files这样使用相对路径。
    #所以，我在这里先获取当前路径，再设置进去。最后加**表示recursive，即循环查找子目录的意思
#    $dir = File.dirname(__FILE__)
#    $dir = $dir + "/IRPlayer/ThirdParty/ffmpeg/**"  #$dir:/Users/wangbing/TempCode/MyLibrary/cfiles/**
#    subcfiles.pod_target_xcconfig = { "HEADER_SEARCH_PATHS" => $dir}
#    subcfiles.pod_target_xcconfig = { "HEADER_SEARCH_PATHS" => "${PODS_ROOT}/Headers/Private/**"}

    #demo工程的配置，上面是对pod工程的设置，当需要对demo工程设置时，使用user_target_xcconfig，这里就不做介绍了

    #相对于public_headers，这些文件不会被公开给Demo
#    subcfiles.private_header_files = "**/ThirdParty/ffmpeg/include/**/*.h"
    #保护目录结构不变，如果不设置，所有头文件都将被放到同一个目录下
#    subcfiles.header_mappings_dir = "IRPlayer/ThirdParty/ffmpeg/include"
#    subcfiles.header_dir = "AA"
#  subcfiles.header_mappings_dir = "**/ThirdParty/ffmpeg/include"
#    subcfiles.public_header_files = "IRPlayer/Class/**/*.h"
  end
end
