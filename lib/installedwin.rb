#
#
#

class StaleGemItem
    attr_reader :name, :version, :atime
    def initialize(name, ver, atime)
        @name = name
        @version = ver
        @atime = atime
    end
end


#-----------------------------------------------
#
#
class GemListTable < Qt::TableWidget
    #
    #
    class Item < Qt::TableWidgetItem
        def initialize(text)
            super(text)
            self.flags = Qt::ItemIsSelectable | Qt::ItemIsEnabled
        end

        def gem
            tableWidget.gem(self)
        end
    end


    # column no
    PACKAGE_NAME = 0
    PACKAGE_VERSION = 1
    PACKAGE_SUMMARY = 2
    PACKAGE_ATIME = 3

    def initialize(title)
        super(0,4)

        self.windowTitle = title
        setHorizontalHeaderLabels(['package', 'version', 'summary', 'last access'])
        self.horizontalHeader.stretchLastSection = true
        self.selectionBehavior = Qt::AbstractItemView::SelectRows
        self.selectionMode = Qt::AbstractItemView::SingleSelection
        self.alternatingRowColors = true
        self.sortingEnabled = true
        sortByColumn(PACKAGE_NAME, Qt::AscendingOrder )
        @gems = {}
    end

    # caution ! : befor call, sortingEnabled must be set false.
    #   if sortingEnabled is on while updating table, it is very sluggish.
    def addPackage(row, gem)
#         self.sortingEnabled = false
        nameItem = Item.new(gem.package)
        @gems[nameItem] = gem           # 0 column item is hash key.
        setItem( row, PACKAGE_NAME, nameItem  )
        setItem( row, PACKAGE_VERSION, Item.new(gem.version) )
        setItem( row, PACKAGE_SUMMARY, Item.new(gem.summary) )
        setItem( row, PACKAGE_ATIME, Item.new('') )
    end


    def updateGemList(gemList)
        sortFlag = self.sortingEnabled
        self.sortingEnabled = false

        clearContents
        self.rowCount = gemList.length
        gemList.each_with_index do |g, r|
            addPackage(r, g)
        end

        self.sortingEnabled = sortFlag
    end


    def gem(item)
        gemAtRow(item.row)
    end

    def gemAtRow(row)
        @gems[item(row,0)]       # use 0 column item as hash key.
    end

    def currentGem
        gemAtRow(currentRow)
    end

    def showall
        rowCount.times do |r|
            showRow(r)
        end
    end


    slots   'filterChanged(const QString &)'
    def filterChanged(text)
        unless text && !text.empty?
            showall
            return
        end

        regxs = /#{Regexp.escape(text.strip)}/i
        rowCount.times do |r|
            gem = gemAtRow(r)
            txt = [ gem.package, gem.summary, gem.author, gem.platform ].inject("") do |s, t|
                        t.nil? ? s : s + t.to_s
            end
            if regxs =~ txt then
                showRow(r)
            else
                hideRow(r)
            end
        end
    end

    # @return : number : row of found item.
    def find
        rowCount.times do |r|
            i = gemAtRow(r)
            return r if yield i
        end
        false
    end
end



#--------------------------------------------------------------------
#
#
class InstalledGemWin < Qt::Widget
    def initialize(parent=nil)
        super(parent)

        createWidget
        readSettings

        Qt::Timer.singleShot(0, self, SLOT(:updateInstalledGemList))
    end

    def createWidget
        @installedGemsTable = GemListTable.new('installed')

        @viewDirBtn = KDE::PushButton.new(KDE::Icon.new('folder'), 'View Directory')
        @viewRdocBtn = KDE::PushButton.new(KDE::Icon.new('help-contents'), 'View RDoc')
        @generateRdocBtn = KDE::PushButton.new(KDE::Icon.new('document-new'), 'Generate RDoc/ri')
        @updateGemBtn = KDE::PushButton.new(KDE::Icon.new('view-refresh'), 'Update')

        @uninstallBtn = KDE::PushButton.new(KDE::Icon.new('list-remove'), 'Uninstall')

        @filterInstalledLineEdit = KDE::LineEdit.new do |w|
            connect(w,SIGNAL('textChanged(const QString &)'),
                    @installedGemsTable, SLOT('filterChanged(const QString &)'))
            w.setClearButtonShown(true)
        end
        @checkTestBtn = KDE::PushButton.new(KDE::Icon.new('checkbox'), 'Test')


        # connect
        connect(@viewDirBtn, SIGNAL(:clicked), self, SLOT(:viewDir))
        connect(@viewRdocBtn, SIGNAL(:clicked), self, SLOT(:viewRdoc))
        connect(@uninstallBtn, SIGNAL(:clicked), self, SLOT(:uninstallGem))
        connect(@installedGemsTable, SIGNAL('itemClicked(QTableWidgetItem *)'),
                    self, SLOT('itemClicked(QTableWidgetItem *)'))
        connect(@generateRdocBtn, SIGNAL(:clicked), self, SLOT(:generateRdoc))
        connect(@updateGemBtn, SIGNAL(:clicked), self, SLOT(:updateGem))
        connect(@checkTestBtn, SIGNAL(:clicked), self, SLOT(:testGem))

        # layout
        lo = Qt::VBoxLayout.new do |w|
                w.addWidgets('Filter:', @filterInstalledLineEdit)
                w.addWidget(@installedGemsTable)
                w.addWidgets(nil, @viewDirBtn, @viewRdocBtn, @generateRdocBtn, @checkTestBtn, @updateGemBtn, @uninstallBtn)
            end
        setLayout(lo)
    end


    GroupName = "InstalledGemWindow"
    def writeSettings
        config = $config.group(GroupName)
        config.writeEntry('Header', @installedGemsTable.horizontalHeader.saveState)
    end

    def readSettings
        config = $config.group(GroupName)
        @installedGemsTable.horizontalHeader.restoreState(config.readEntry('Header', @installedGemsTable.horizontalHeader.saveState))
    end


    #------------------------------------
    #
    #
    def notifyInstall
        updateInstalledGemList
    end

    slots :testGem
    def testGem
        gem = @installedGemsTable.currentGem
        return unless gem

        @gemViewer.testGem(gem)
    end

    slots :updateGem
    def updateGem
        gem = @installedGemsTable.currentGem
        return unless gem

        @gemViewer.updateGem(gem)
    end

    slots :generateRdoc
    def generateRdoc
        gem = @installedGemsTable.currentGem
        return unless gem

        @gemViewer.generateRdoc(gem)
    end

    slots :updateInstalledGemList
    def updateInstalledGemList
        gemList = InstalledGemList.get
        @installedGemsTable.updateGemList(gemList)
    end

    def setStaleTime(stales)
        stales.each do |i|
            r = @installedGemsTable.find do |g|
                    g.name == i.name && g.version == i.version
            end
            if r then
                @installedGemsTable.item(r, GemListTable::PACKAGE_ATIME).text = i.atime.to_s
            end
        end
        @installedGemsTable.sortItems(GemListTable::PACKAGE_ATIME)
        @installedGemsTable.clearSelection
        parent.parent.currentIndex = parent.indexOf(self)
    end

    attr_accessor :gemViewer
    slots 'itemClicked(QTableWidgetItem *)'
    def itemClicked(item)
        unless item.gem.spec then
            specStr = GemCmd.exec("specification #{item.gem.package} -l --marshal")
            begin
                spec = Marshal.load(specStr)
            rescue NoMethodError, ArgumentError => e
                # rescue from some error gems.
                @gemViewer.setError(item.gem, e)
                return
            end
            item.gem.spec = spec
        end
        @gemViewer.setDetail( item.gem )
        files = GemCmd.exec("contents --prefix #{item.gem.package} -v #{item.gem.version}").split(/\n/)
        @gemViewer.setFiles( files )

        proc = lambda do |item|
            file = item.text
            @gemViewer.previewWin.setFile( file )
        end
        @gemViewer.setPreviewProc(proc)
    end

    slots :viewRdoc
    def viewRdoc
        @gemViewer.viewGemRdoc(@installedGemsTable.currentGem)
    end


    slots :viewDir
    def viewDir
        @gemViewer.viewGemDir(@installedGemsTable.currentGem)
    end

    slots :uninstallGem
    def uninstallGem
        @gemViewer.uninstall(@installedGemsTable.currentGem)
    end
end
