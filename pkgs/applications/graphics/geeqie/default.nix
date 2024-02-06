{ lib, stdenv, fetchFromGitHub, pkg-config, meson, ninja, xxd, gettext, intltool
, gtk3, lcms2, exiv2, libchamplain, clutter-gtk, ffmpegthumbnailer, fbida
, libarchive, djvulibre, libheif, openjpeg, libjxl, libraw, lua5_3, poppler
, gspell, libtiff, libwebp
, gphoto2, imagemagick, yad, exiftool, gnome, libnotify
, wrapGAppsHook, fetchpatch, doxygen
, nix-update-script
}:

stdenv.mkDerivation rec {
  pname = "geeqie";
  version = "2.2";

  src = fetchFromGitHub {
    owner = "BestImageViewer";
    repo = "geeqie";
    rev = "v${version}";
    hash = "sha256-13Ayr6r4JhqexaUvwzdc6XHT+j2l2D5YBws6gSAhU3Y=";
  };

  patches = [
    # Remove changelog from menu
    (fetchpatch {
      url = "https://salsa.debian.org/debian/geeqie/-/raw/debian/master/debian/patches/Remove-changelog-from-menu-item.patch";
      hash = "sha256-0awKKTLg/gUZhmwluVbHCOqssog9SneFOaUtG89q0go=";
    })
    # Fix missing execute permissions for geocode-parametres.awk plugin
    (fetchpatch {
      url = "https://github.com/BestImageViewer/geeqie/commit/4d3ddcf5b9c0668bfdaf1dfe24219ee57c2f0237.patch";
      hash = "sha256-Na2qiwCTbOv1yt251oaSZiLaOwJCkjWew+us4lQju0I=";
    })
  ];

  postPatch = ''
    patchShebangs .
  '';

  nativeBuildInputs =
    [ pkg-config gettext intltool
      wrapGAppsHook doxygen
      meson ninja xxd
    ];

  buildInputs = [
    gtk3 lcms2 exiv2 libchamplain clutter-gtk ffmpegthumbnailer fbida
    libarchive djvulibre libheif openjpeg libjxl libraw lua5_3 poppler
    gspell libtiff libwebp
  ];

  postInstall = ''
    # Allow geeqie to find exiv2 and exiftran, necessary to
    # losslessly rotate JPEG images.
    # Requires exiftran (fbida package) and exiv2.
    sed -i $out/lib/geeqie/geeqie-rotate \
        -e '1 a export PATH=${lib.makeBinPath [ exiv2 fbida ]}:$PATH'
    # Zenity and yad are used in some scripts for reporting errors.
    # Allow change quality of image.
    # Requires imagemagick and yad.
    sed -i $out/lib/geeqie/geeqie-resize-image \
        -e '1 a export PATH=${lib.makeBinPath [ imagemagick yad ]}:$PATH'
    # Allow to crop image.
    # Requires imagemagick, exiv2 and exiftool.
    sed -i $out/lib/geeqie/geeqie-image-crop \
        -e '1 a export PATH=${lib.makeBinPath [ imagemagick exiv2 exiftool gnome.zenity ]}:$PATH'
    # Requires gphoto2 and libnotify
    sed -i $out/lib/geeqie/geeqie-tethered-photography \
        -e '1 a export PATH=${lib.makeBinPath [ gphoto2 gnome.zenity libnotify ]}:$PATH'
    # Import images from camera.
    # Requires gphoto2.
    sed -i $out/lib/geeqie/geeqie-camera-import \
        -e '1 a export PATH=${lib.makeBinPath [ gphoto2 gnome.zenity ]}:$PATH'
    # Export jpeg from raw file.
    # Requires exiv2, exiftool and lcms2.
    sed -i $out/lib/geeqie/geeqie-export-jpeg \
        -e '1 a export PATH=${lib.makeBinPath [ gnome.zenity exiv2 exiftool lcms2 ]}:$PATH'
  '';

  enableParallelBuilding = true;

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = with lib; {
    description = "Lightweight GTK based image viewer";

    longDescription =
      ''
        Geeqie is a lightweight GTK based image viewer for Unix like
        operating systems.  It features: EXIF, IPTC and XMP metadata
        browsing and editing interoperability; easy integration with other
        software; geeqie works on files and directories, there is no need to
        import images; fast preview for many raw image formats; tools for
        image comparison, sorting and managing photo collection.  Geeqie was
        initially based on GQview.
      '';

    license = licenses.gpl2Plus;

    homepage = "https://www.geeqie.org/";

    maintainers = with maintainers; [ pSub markus1189 ];
    platforms = platforms.gnu ++ platforms.linux;
  };
}
