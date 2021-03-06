#
#   settings.
#
#
require "mylibs"


TrustPolicies = %w{ NoSecurity LowSecurity MediumSecurity HighSecurity }

class Settings < SettingsBase
    def initialize
        super()

        setCurrentGroup("Preferences")

        # folder settings.
        addBoolItem(:autoFetchFlag, false)
        addStringItem(:autoFetchDir,
                   File.join(KDE::GlobalSettings.downloadPath, 'gem_cache'))
        addBoolItem(:autoUnpackFlag, false)
        addStringItem(:autoUnpackDir, File.join(KDE::GlobalSettings.downloadPath, 'gem_src'))
        addBoolItem(:installLatestFlag, false)
        addBoolItem(:downloadLatestFlag, false)

        # install option settings.
        addBoolItem(:installInSystemDirFlag, true)
        addBoolItem(:installRdocFlag, true)
        addBoolItem(:installRiFlag, true)
        addBoolItem(:installSheBangFlag, false)
        addBoolItem(:installUnitTestFlag, false)
        addBoolItem(:installBinWrapFlag, false)
        addBoolItem(:installIgnoreDepsFlag, false)
        addBoolItem(:installIncludeDepsFlag, false)
        addBoolItem(:installDevelopmentDepsFlag, false)
        addBoolItem(:installformatExecutableFlag, false)
        addIntItem(:installTrustPolicy, 0)
    end

    def installTrustPolicyStr
        TrustPolicies[installTrustPolicy]
    end
end


class GeneralSettingsPage < Qt::Widget
    def initialize(parent=nil)
        super(parent)
        createWidget
    end

    def createWidget
        @autoFetchCheckBox = Qt::CheckBox.new(i18n("Always Download gem in same directory."))
        @downloadUrl = FolderSelectorLineEdit.new
        @downloadUrl.enabled = false
        connect(@autoFetchCheckBox, SIGNAL('stateChanged(int)'),
                self, SLOT('autoFetchChanged(int)'))

        @autoUnpackCheckBox = Qt::CheckBox.new(i18n("Always Unpack gem in same directory."))
        @unpackUrl = FolderSelectorLineEdit.new
        @unpackUrl.enabled = false
        connect(@autoUnpackCheckBox, SIGNAL('stateChanged(int)'),
                self, SLOT('autoUnpackChanged(int)'))
        @installLatestCheckBox = Qt::CheckBox.new(i18n("Always Install latest version to skip version selection."))
        @downloadLatestCheckBox = Qt::CheckBox.new(i18n("Always Download latest version to skip version selection."))

        @openDownloadDir = KDE::PushButton.new(KDE::Icon.new('folder'), 'Open')
        @openUnpackDir = KDE::PushButton.new(KDE::Icon.new('folder'), 'Open')
        connect(@openDownloadDir, SIGNAL(:clicked), self, SLOT(:openDownloadDir))
        connect(@openUnpackDir, SIGNAL(:clicked), self, SLOT(:openUnpackDir))

        # objectNames
        #  'kcfg_' + class Settings's instance name.
        @autoFetchCheckBox.objectName = 'kcfg_autoFetchFlag'
        @downloadUrl.objectName = 'kcfg_autoFetchDir'
        @autoUnpackCheckBox.objectName = 'kcfg_autoUnpackFlag'
        @unpackUrl.objectName = 'kcfg_autoUnpackDir'
        @installLatestCheckBox.objectName = 'kcfg_installLatestFlag'
        @downloadLatestCheckBox.objectName = 'kcfg_downloadLatestFlag'

        # layout
        lo = Qt::VBoxLayout.new do |l|
            l.addWidget(@installLatestCheckBox)
            l.addWidget(@downloadLatestCheckBox)
            l.addWidget(@autoFetchCheckBox)
            l.addWidgets('   ', @downloadUrl, @openDownloadDir)
            l.addWidget(@autoUnpackCheckBox)
            l.addWidgets('   ', @unpackUrl, @openUnpackDir)
            l.addStretch
        end
        setLayout(lo)
    end

    slots   'autoFetchChanged(int)'
    def autoFetchChanged(state)
        @downloadUrl.enabled = state == Qt::Checked
        @openDownloadDir.enabled = state == Qt::Checked
    end

    slots   'autoUnpackChanged(int)'
    def autoUnpackChanged(state)
        @unpackUrl.enabled = state == Qt::Checked
        @openUnpackDir.enabled = state == Qt::Checked
    end

    slots :openDownloadDir
    def openDownloadDir
        openDirectory(@downloadUrl.text)
    end

    slots :openUnpackDir
    def openUnpackDir
        openDirectory(@unpackUrl.text)
    end
end


class InstallOptionsPage < Qt::Widget
    def initialize(parent=nil)
        super(parent)
        createWidget
    end

    def createWidget
        @installInSystemCheckBox = Qt::CheckBox.new(i18n("Install in System Directory. (Root access Required)"))
        @rdocCheckBox = Qt::CheckBox.new(i18n('Generate RDoc Documentation'))
        @riCheckBox = Qt::CheckBox.new(i18n('Generate RI Documentation'))
        @sheBangCheckBox = Qt::CheckBox.new(i18n('Rewrite the shebang line on installed scripts to use /usr/bin/env'))
        @utestCheckBox = Qt::CheckBox.new(i18n('Run unit tests prior to installation'))
        @binWrapCheckBox = Qt::CheckBox.new(i18n('Use bin wrappers for executables'))
#         @policyCheckBox = Qt::ComboBox.new
#             Qt::Label.new(i18n('Specify gem trust policy'))
        @ignoreDepsCheckBox = Qt::CheckBox.new(i18n('Do not install any required dependent gems'))
        @includeDepsCheckBox = Qt::CheckBox.new(i18n('Unconditionally install the required dependent gems'))
        @developmentDepsCheckBox = Qt::CheckBox.new(i18n('Install any additional development dependencies'))
        @formatExecutableCheckBox = Qt::CheckBox.new(i18n('Make installed executable names match ruby.'))
        formatExeLabel = Qt::Label.new(i18n('     If ruby is ruby18, foo_exec will be foo_exec18'))
#         formatExeLabel.wordWrap = true
        @trustPolicyComboBox = Qt::ComboBox.new
        @trustPolicyComboBox.addItems(TrustPolicies)

        # connect signals,slots
        connect(@utestCheckBox, SIGNAL('stateChanged(int)'), self, \
                SLOT('utestChanged(int)'))
        connect(@developmentDepsCheckBox, SIGNAL('stateChanged(int)'), self, \
                SLOT('devDepsChanged(int)'))

        # objectNames
        #  'kcfg_' + class Settings's instance name.
        @installInSystemCheckBox.objectName = 'kcfg_installInSystemDirFlag'
        @rdocCheckBox.objectName = 'kcfg_installRdocFlag'
        @riCheckBox.objectName = 'kcfg_installRiFlag'
        @sheBangCheckBox.objectName = 'kcfg_installSheBangFlag'
        @utestCheckBox.objectName = 'kcfg_installUnitTestFlag'
        @binWrapCheckBox.objectName = 'kcfg_installBinWrapFlag'
        @ignoreDepsCheckBox.objectName = 'kcfg_installIgnoreDepsFlag'
        @includeDepsCheckBox.objectName = 'kcfg_installIncludeDepsFlag'
        @developmentDepsCheckBox.objectName = 'kcfg_installDevelopmentDepsFlag'
        @formatExecutableCheckBox.objectName = 'kcfg_installformatExecutableFlag'
        @trustPolicyComboBox.objectName = 'kcfg_installTrustPolicy'

        # layout
        lo = Qt::VBoxLayout.new do |l|
            l.addWidget(@installInSystemCheckBox)
            l.addWidget(@rdocCheckBox)
            l.addWidget(@riCheckBox)
            l.addWidget(@sheBangCheckBox)
            l.addWidget(@utestCheckBox)
            l.addWidget(@binWrapCheckBox)
            l.addWidget(@ignoreDepsCheckBox)
            l.addWidget(@includeDepsCheckBox)
            l.addWidget(@developmentDepsCheckBox)
            l.addWidget(@formatExecutableCheckBox)
            l.addWidget(formatExeLabel)
            l.addWidgets(i18n('Trust Policy :'), @trustPolicyComboBox, nil)
            l.addStretch
        end
        setLayout(lo)
    end

    slots 'utestChanged(int)'
    def utestChanged(state)
        @developmentDepsCheckBox.setCheckState(state)
    end

    slots 'devDepsChanged(int)'
    def devDepsChanged(state)
        @utestCheckBox.setCheckState(state) if state == Qt::Unchecked
    end

    def installInSystemVisible=(flag)
        @installInSystemCheckBox.visible = flag
    end
end

class SettingsDlg < KDE::ConfigDialog
    def initialize(parent)
        super(parent, "Settings", Settings.instance)

        addPage(GeneralSettingsPage.new, i18n("General"), 'preferences-system')
        addPage(InstallOptionsPage.new, i18n("Install Options"), 'applications-other')
    end
end