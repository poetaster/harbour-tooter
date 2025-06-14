# 
# Do NOT Edit the Auto-generated Part!
# Generated by: spectacle version 0.32
# 

Name:       harbour-tooterb

# >> macros
%define _binary_payload w2.xzdio
# << macros

%{!?qtc_qmake:%define qtc_qmake %qmake}
%{!?qtc_qmake5:%define qtc_qmake5 %qmake5}
%{!?qtc_make:%define qtc_make make}
%{?qtc_builddir:%define _builddir %qtc_builddir}
Summary:    Tooter β
Version:    1.2.1
Release:    1
Group:      Qt/Qt
License:    GPLv3
URL:        https://github.com/poetaster/harbour-tooter#readme
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   nemo-qml-plugin-configuration-qt5
Requires:   amber-web-authorization

BuildRequires:  qt5-qttools-linguist
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(Qt5DBus)
BuildRequires:  pkgconfig(Qt5Multimedia)
BuildRequires:  pkgconfig(nemonotifications-qt5)
BuildRequires:  pkgconfig(openssl)
BuildRequires:  desktop-file-utils

%description
Tooter Beta is a native client for Mastodon network instances.

%if "%{?vendor}" == "chum"
PackageName: Tooter β
Type: desktop-application
Categories:
 - Network
PackagerName: Mark Washeim (poetaster)
Custom:
 - Repo: https://github.com/poetaster/harbour-tooter
PackageIcon: https://raw.githubusercontent.com/poetaster/harbour-tooter/master/icons/256x256/harbour-tooterb.png
Url:
 - Bugtracker: https://github.com/poetaster/harbour-tooter/issues
Screenshots:
 - https://github.com/poetaster/harbour-tooter/raw/master/screenshots/screenshot1.png
 - https://github.com/poetaster/harbour-tooter/raw/master/screenshots/screenshot2.png
 - https://github.com/poetaster/harbour-tooter/raw/master/screenshots/screenshot3.png
Links:
  Homepage: https://github.com/poetaster/harbour-tooter
  Bugtracker: https://github.com/poetaster/harbour-tooter/issues
  Donation: https://liberapay.com/poetaster
%endif

%prep
%setup -q -n %{name}-%{version}

# >> setup
# << setup

%build
# >> build pre
# << build pre

%qtc_qmake5 

%qtc_make %{?_smp_mflags}

# >> build post
# << build post

%install
rm -rf %{buildroot}
# >> install pre
# << install pre
%qmake5_install

# >> install post
# << install post

desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
# >> files
# << files
