Name:       harbour-tooterb

%define _binary_payload w2.xzdio
%define __provides_exclude_from ^%{_datadir}/.*$

Summary:    Tooter β
Version:    1.3.4
Release:    2
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

%build

%qmake5 VERSION=%{version} RELEASE=%{release}

%make_build


%install
%qmake5_install

desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
