Name:       harbour-tooterb

%define _binary_payload w2.xzdio
%define __provides_exclude_from ^%{_datadir}/.*$

%if "%{?vendor}" == "chum"
%bcond_with harbour
%else
%bcond_without harbour
%endif

Summary:    Tooter β
Version:    1.4.0
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

%build


%if "%{?vendor}" == "chum"
 %qmake5 VERSION=%{version} RELEASE=%{release}
%else
 HARBOUR_STORE=1 MB2_QMAKE_ARGS='CONFIG+=harbour_store' %qmake5 QMAKE_ARGS='CONFIG+=harbour_store' 'CONFIG+=harbour_store'
%endif

%make_build

%install
%qmake5_install

desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/%{name}.desktop

%files
%defattr(-,root,root,-)
%{_bindir}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%if "%{?vendor}" == "chum"
 %{_datadir}/applications/%{name}-open-url.desktop
 %{_datadir}/d-bus1/services/de.poetaster.harbour.tooterb.service
 %{_datadir}/lipstick/notificationcategories/x-harbour.tooterb.activity.conf
%endif
%{_datadir}/icons/hicolor/*/apps/%{name}.png
