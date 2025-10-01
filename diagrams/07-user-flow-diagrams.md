# User Flow Diagrams

**Purpose:** Shows user journey through the application for key tasks

**Last Updated:** 2025-09-30

**Version:** 1.0.0

## Upload Document User Flow

```mermaid
graph TD
    START([User Opens App]) --> LOGIN{Already<br/>Authenticated?}
    LOGIN -->|No| ENTERKEY[Enter API Key]
    ENTERKEY --> DASHBOARD[View Dashboard]
    LOGIN -->|Yes| DASHBOARD

    DASHBOARD --> BROWSE[Navigate to Browse View]
    BROWSE --> SELECTFOLDER[Select Target Folder<br/>from Tree]

    SELECTFOLDER --> UPLOADBTN[Click Upload Button]
    UPLOADBTN --> CHOOSEFILE{File Selection<br/>Method?}

    CHOOSEFILE -->|Browse| OPENDIALOG[Open File Dialog]
    CHOOSEFILE -->|Drag-Drop| DRAGFILE[Drag File to Upload Area]

    OPENDIALOG --> FILESELECTED[File Selected]
    DRAGFILE --> FILESELECTED

    FILESELECTED --> VALIDATE{File Valid?}
    VALIDATE -->|No - Too Large| SHOWERROR1[Show Error:<br/>'File exceeds 5GB']
    VALIDATE -->|No - Wrong Type| SHOWERROR2[Show Error:<br/>'Invalid file type']
    SHOWERROR1 --> CHOOSEFILE
    SHOWERROR2 --> CHOOSEFILE

    VALIDATE -->|Yes| METADATA[Metadata Entry Form]
    METADATA --> ADDNAME[Enter Document Name<br/>defaults to filename]
    ADDNAME --> ADDFIELDS[Add Custom Metadata<br/>key-value pairs]
    ADDFIELDS --> ADDTAGS[Add Tags<br/>autocomplete from existing]

    ADDTAGS --> REVIEWUPLOAD[Review Upload Details]
    REVIEWUPLOAD --> CONFIRMDECISION{User Decision?}

    CONFIRMDECISION -->|Cancel| BROWSE
    CONFIRMDECISION -->|Upload| STARTUPLOAD[Start Upload]

    STARTUPLOAD --> PROGRESS[Show Progress Bar<br/>with percentage]
    PROGRESS --> UPLOADING{Upload<br/>Status?}

    UPLOADING -->|In Progress| PROGRESS
    UPLOADING -->|Failed| UPLOADFAIL[Show Error Message]
    UPLOADFAIL --> RETRYDECISION{Retry?}
    RETRYDECISION -->|Yes| STARTUPLOAD
    RETRYDECISION -->|No| BROWSE

    UPLOADING -->|Success| SUCCESS[Show Success Message]
    SUCCESS --> UPDATEDLIST[Document Appears in List]
    UPDATEDLIST --> NEXTACTION{What Next?}

    NEXTACTION -->|Upload More| UPLOADBTN
    NEXTACTION -->|View Document| VIEWDOC[Open Document Details]
    NEXTACTION -->|Browse| BROWSE
    NEXTACTION -->|Done| END([End])

    VIEWDOC --> END

    style START fill:#e1f5ff,stroke:#01579b,stroke-width:3px
    style END fill:#f8bbd0,stroke:#c2185b,stroke-width:3px
    style VALIDATE fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style UPLOADING fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style SUCCESS fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style SHOWERROR1 fill:#ffccbc,stroke:#d84315,stroke-width:2px
    style SHOWERROR2 fill:#ffccbc,stroke:#d84315,stroke-width:2px
    style UPLOADFAIL fill:#ffccbc,stroke:#d84315,stroke-width:2px
```

## Search and Find Document User Flow

```mermaid
graph TD
    START([User Needs Document]) --> OPENSEARCH{Where to<br/>Search?}

    OPENSEARCH -->|Quick Search| HEADERBAR[Use Search Bar in Header]
    OPENSEARCH -->|Advanced| SEARCHPAGE[Go to Search Page]

    HEADERBAR --> TYPESEARCH[Type Search Query]
    SEARCHPAGE --> TYPESEARCH

    TYPESEARCH --> DEBOUNCE[System Debounces Input<br/>300ms]
    DEBOUNCE --> SHOWRESULTS[Show Live Results]

    SHOWRESULTS --> CHECKRESULTS{Found What<br/>Needed?}

    CHECKRESULTS -->|Yes| CLICKDOC[Click on Document]
    CHECKRESULTS -->|No - Refine| ADDFILTERS[Add Filters]

    ADDFILTERS --> FILTERTAGS[Filter by Tags]
    FILTERTAGS --> FILTERFOLDER[Filter by Folder]
    FILTERFOLDER --> FILTERDATE[Filter by Date Range]
    FILTERDATE --> APPLYFILTERS[Apply Filters]
    APPLYFILTERS --> SHOWRESULTS

    CHECKRESULTS -->|No - Try Different| TYPESEARCH

    CLICKDOC --> VIEWDETAILS[View Document Details Panel]
    VIEWDETAILS --> ACTIONS{What Action?}

    ACTIONS -->|Download| DOWNLOAD[Download Document]
    ACTIONS -->|View Metadata| METADATA[View Full Metadata]
    ACTIONS -->|Edit| EDIT[Edit Document]
    ACTIONS -->|Move| MOVE[Move to Different Folder]
    ACTIONS -->|Delete| DELETE[Delete Document]
    ACTIONS -->|Navigate to Folder| GOFOLDER[Go to Folder Location]

    DOWNLOAD --> DOWNLOADSUCCESS[File Downloaded]
    DOWNLOADSUCCESS --> COMPLETE([Document Obtained])

    METADATA --> VIEWDETAILS
    EDIT --> EDITFLOW[Edit Metadata Flow]
    EDITFLOW --> COMPLETE
    MOVE --> MOVEFLOW[Move Document Flow]
    MOVEFLOW --> COMPLETE
    DELETE --> DELETEFLOW[Delete Confirmation Flow]
    DELETEFLOW --> COMPLETE
    GOFOLDER --> BROWSEFOLDER[Browse Folder View]
    BROWSEFOLDER --> COMPLETE

    style START fill:#e1f5ff,stroke:#01579b,stroke-width:3px
    style COMPLETE fill:#c8e6c9,stroke:#2e7d32,stroke-width:3px
    style CHECKRESULTS fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style ACTIONS fill:#fff9c4,stroke:#f57f17,stroke-width:2px
```

## Create Folder Structure User Flow

```mermaid
graph TD
    START([User Wants Organization]) --> DECIDE{Need New<br/>Folder?}

    DECIDE -->|Yes| NAVIGATE[Navigate to Parent Location]
    DECIDE -->|No - Reorganize| REORGANIZE[Move Existing Folders]

    NAVIGATE --> SELECTPARENT[Select Parent Folder<br/>from Tree]
    SELECTPARENT --> NEWFOLDER[Click New Folder Button]

    NEWFOLDER --> DIALOG[Folder Creation Dialog Opens]
    DIALOG --> ENTERNAME[Enter Folder Name]
    ENTERNAME --> ENTERDESC[Enter Description<br/>optional]
    ENTERDESC --> PREVIEW[Preview Folder Path]

    PREVIEW --> VALIDATE{Valid?}
    VALIDATE -->|No - Name Exists| ERROR1[Error: Name already exists<br/>in this location]
    VALIDATE -->|No - Too Deep| ERROR2[Error: Maximum depth<br/>exceeded 10 levels]
    VALIDATE -->|No - Empty Name| ERROR3[Error: Folder name<br/>required]

    ERROR1 --> ENTERNAME
    ERROR2 --> SELECTPARENT
    ERROR3 --> ENTERNAME

    VALIDATE -->|Yes| CONFIRM{Create Folder?}
    CONFIRM -->|Cancel| CANCEL[Close Dialog]
    CANCEL --> BROWSE[Browse View]

    CONFIRM -->|Create| CREATEFOLDER[Create Folder API Call]
    CREATEFOLDER --> CREATING{Result?}

    CREATING -->|Failed| CREATEERROR[Show Error Message]
    CREATEERROR --> RETRY{Retry?}
    RETRY -->|Yes| CREATEFOLDER
    RETRY -->|No| BROWSE

    CREATING -->|Success| FOLDERCREATED[Folder Created]
    FOLDERCREATED --> TREEUPDATE[Tree Updates with New Folder]
    TREEUPDATE --> SUCCESSMSG[Show Success Message]

    SUCCESSMSG --> NEXTACTION{What Next?}
    NEXTACTION -->|Create Subfolder| NEWFOLDER
    NEXTACTION -->|Upload Documents| UPLOADDOCS[Upload Documents Flow]
    NEXTACTION -->|Create Sibling| SELECTPARENT
    NEXTACTION -->|Done| END([End])

    REORGANIZE --> SELECTMOVING[Select Folder to Move]
    SELECTMOVING --> DRAGORCLICK{Move Method?}
    DRAGORCLICK -->|Drag-Drop| DRAGTARGET[Drag to Target Parent]
    DRAGORCLICK -->|Menu| MOVEMENU[Click Move from Menu]
    MOVEMENU --> SELECTTARGET[Select Target Parent]

    DRAGTARGET --> VALIDATEHIERARCHY{Valid Move?}
    SELECTTARGET --> VALIDATEHIERARCHY

    VALIDATEHIERARCHY -->|No - Circular| ERRORCIRCULAR[Error: Cannot move to<br/>own descendant]
    VALIDATEHIERARCHY -->|No - Depth| ERRORDEPTH[Error: Would exceed<br/>max depth]
    ERRORCIRCULAR --> REORGANIZE
    ERRORDEPTH --> REORGANIZE

    VALIDATEHIERARCHY -->|Yes| CONFIRMMOVE[Confirm Move]
    CONFIRMMOVE --> MOVEFOLDER[Move Folder API Call]
    MOVEFOLDER --> MOVING{Result?}

    MOVING -->|Failed| MOVEERROR[Show Error Message]
    MOVEERROR --> REORGANIZE
    MOVING -->|Success| MOVED[Folder Moved]
    MOVED --> TREEUPDATED[Tree Structure Updated]
    TREEUPDATED --> END

    UPLOADDOCS --> END

    style START fill:#e1f5ff,stroke:#01579b,stroke-width:3px
    style END fill:#c8e6c9,stroke:#2e7d32,stroke-width:3px
    style VALIDATE fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style CREATING fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style VALIDATEHIERARCHY fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style ERROR1 fill:#ffccbc,stroke:#d84315,stroke-width:2px
    style ERROR2 fill:#ffccbc,stroke:#d84315,stroke-width:2px
    style ERROR3 fill:#ffccbc,stroke:#d84315,stroke-width:2px
    style CREATEERROR fill:#ffccbc,stroke:#d84315,stroke-width:2px
    style ERRORCIRCULAR fill:#ffccbc,stroke:#d84315,stroke-width:2px
    style ERRORDEPTH fill:#ffccbc,stroke:#d84315,stroke-width:2px
```

## Edit Document Metadata User Flow

```mermaid
graph TD
    START([User Finds Document]) --> LOCATION{Where?}

    LOCATION -->|Folder View| DOCLIST[Document List]
    LOCATION -->|Search Results| SEARCHRESULTS[Search Results]
    LOCATION -->|Recent Docs| RECENTLIST[Recent Documents]

    DOCLIST --> SELECTDOC[Select Document]
    SEARCHRESULTS --> SELECTDOC
    RECENTLIST --> SELECTDOC

    SELECTDOC --> VIEWOPTIONS{Action?}
    VIEWOPTIONS -->|View Details| DETAILS[View Details Panel]
    VIEWOPTIONS -->|Quick Edit| EDITBTN[Click Edit Icon]

    DETAILS --> EDITBTN
    EDITBTN --> EDITDIALOG[Metadata Editor Opens]

    EDITDIALOG --> EDITNAME[Edit Document Name]
    EDITNAME --> EDITMETADATA[Edit Metadata Fields]
    EDITMETADATA --> ADDREMOVEFIELDS{Modify Fields?}

    ADDREMOVEFIELDS -->|Add Field| ADDFIELD[Add New Key-Value Pair]
    ADDREMOVEFIELDS -->|Remove Field| REMOVEFIELD[Remove Field]
    ADDREMOVEFIELDS -->|Edit Value| EDITVALUE[Modify Value]
    ADDREMOVEFIELDS -->|Done| EDITTAGS

    ADDFIELD --> EDITMETADATA
    REMOVEFIELD --> EDITMETADATA
    EDITVALUE --> EDITMETADATA

    EDITTAGS --> TAGACTIONS{Modify Tags?}
    TAGACTIONS -->|Add Tag| ADDTAG[Select or Create Tag]
    TAGACTIONS -->|Remove Tag| REMOVETAG[Remove Tag]
    TAGACTIONS -->|Done| REVIEWCHANGES

    ADDTAG --> AUTOCOMPLETE{Existing Tag?}
    AUTOCOMPLETE -->|Yes| SELECTEXISTING[Select from Autocomplete]
    AUTOCOMPLETE -->|No| CREATENEW[Create New Tag]
    SELECTEXISTING --> EDITTAGS
    CREATENEW --> EDITTAGS
    REMOVETAG --> EDITTAGS

    REVIEWCHANGES --> PREVIEW[Preview All Changes]
    PREVIEW --> VALIDATESAVE{Valid?}

    VALIDATESAVE -->|No - Invalid Name| ERRORNAME[Error: Name required]
    VALIDATESAVE -->|No - Too Many Tags| ERRORTAGS[Error: Max 50 tags]
    VALIDATESAVE -->|No - Too Many Fields| ERRORFIELDS[Error: Max 20 metadata fields]

    ERRORNAME --> EDITNAME
    ERRORTAGS --> EDITTAGS
    ERRORFIELDS --> EDITMETADATA

    VALIDATESAVE -->|Yes| CONFIRMSAVE{Save Changes?}
    CONFIRMSAVE -->|Cancel| DISCARD[Discard Changes]
    DISCARD --> VIEWDOC[View Document]
    VIEWDOC --> END([End])

    CONFIRMSAVE -->|Save| SAVECHANGES[Save API Call]
    SAVECHANGES --> SAVING{Result?}

    SAVING -->|Failed| SAVEERROR[Show Error Message]
    SAVEERROR --> RETRYOPTION{Retry?}
    RETRYOPTION -->|Yes| SAVECHANGES
    RETRYOPTION -->|No| EDITDIALOG

    SAVING -->|Success| SAVED[Changes Saved]
    SAVED --> UPDATEDISPLAY[Update Document Display]
    UPDATEDISPLAY --> SUCCESSMSG[Show Success Message]
    SUCCESSMSG --> VIEWDOC

    style START fill:#e1f5ff,stroke:#01579b,stroke-width:3px
    style END fill:#c8e6c9,stroke:#2e7d32,stroke-width:3px
    style VALIDATESAVE fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style SAVING fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style SAVED fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style ERRORNAME fill:#ffccbc,stroke:#d84315,stroke-width:2px
    style ERRORTAGS fill:#ffccbc,stroke:#d84315,stroke-width:2px
    style ERRORFIELDS fill:#ffccbc,stroke:#d84315,stroke-width:2px
    style SAVEERROR fill:#ffccbc,stroke:#d84315,stroke-width:2px
```

## Mobile Document Access User Flow

```mermaid
graph TD
    START([User Opens App on Mobile]) --> RESPONSIVE[Mobile-Responsive UI Loads]

    RESPONSIVE --> MOBILENAV{Navigation<br/>Method?}

    MOBILENAV -->|Menu| OPENMENU[Tap Hamburger Menu]
    MOBILENAV -->|Search| MOBILESEARCH[Use Search Bar]
    MOBILENAV -->|Recent| VIEWRECENT[View Recent Documents]

    OPENMENU --> SIDEMENU[Side Menu Opens]
    SIDEMENU --> FOLDERTREE[Folder Tree<br/>Touch-Optimized]
    FOLDERTREE --> TAPFOLDER[Tap to Expand Folder]
    TAPFOLDER --> EXPANDFOLDER[Folder Expands]
    EXPANDFOLDER --> TAPAGAIN{Tap Again?}
    TAPAGAIN -->|Expand Child| TAPFOLDER
    TAPAGAIN -->|Select Folder| SELECTFOLDER[Open Folder]

    SELECTFOLDER --> DOCLIST[Document List<br/>Card View]
    VIEWRECENT --> DOCLIST

    MOBILESEARCH --> TYPEMOBILE[Type Search Query<br/>Mobile Keyboard]
    TYPEMOBILE --> SEARCHRESULTS[View Results]
    SEARCHRESULTS --> DOCLIST

    DOCLIST --> SWIPE{Swipe<br/>Action?}
    SWIPE -->|Swipe Left| QUICKACTIONS[Quick Actions Menu<br/>Download/Share/Delete]
    SWIPE -->|Swipe Right| SHOWMORE[Show More Info]
    SWIPE -->|Tap| TAPDOC[Tap Document]

    TAPDOC --> DOCDETAILS[Document Details<br/>Bottom Sheet]
    QUICKACTIONS --> DOCDETAILS

    DOCDETAILS --> DETAILACTIONS{What Action?}

    DETAILACTIONS -->|Download| CHECKSIZE{File Size?}
    CHECKSIZE -->|Large >10MB| WARNSIZE[Warning: Large File<br/>Use WiFi]
    WARNSIZE --> CONFIRMDOWNLOAD{Proceed?}
    CONFIRMDOWNLOAD -->|No| DOCDETAILS
    CONFIRMDOWNLOAD -->|Yes| DOWNLOAD
    CHECKSIZE -->|Small| DOWNLOAD[Download File]

    DOWNLOAD --> DOWNLOADPROGRESS[Show Progress]
    DOWNLOADPROGRESS --> DOWNLOADED[File Downloaded]
    DOWNLOADED --> OPENFILE[Open in Mobile Viewer]
    OPENFILE --> FILEVIEWER[PDF/Image/Document Viewer]
    FILEVIEWER --> END([End])

    DETAILACTIONS -->|Share| SHAREMENU[Native Share Menu]
    SHAREMENU --> SHARELINK[Share Document Link]
    SHARELINK --> END

    DETAILACTIONS -->|View Details| FULLDETAILS[Full Metadata View<br/>Scrollable]
    FULLDETAILS --> DOCDETAILS

    DETAILACTIONS -->|Upload| MOBILEUPLOAD[Mobile Upload Flow]
    MOBILEUPLOAD --> CHOOSESOURCE{File Source?}
    CHOOSESOURCE -->|Camera| OPENCAMERA[Open Camera]
    CHOOSESOURCE -->|Gallery| OPENGALLERY[Open Photo Gallery]
    CHOOSESOURCE -->|Files| OPENFILES[Open File Picker]

    OPENCAMERA --> TAKEPHOTO[Take Photo]
    TAKEPHOTO --> PHOTOCAPTURED[Photo Captured]
    PHOTOCAPTURED --> UPLOADPREVIEW[Preview Upload]

    OPENGALLERY --> SELECTPHOTO[Select Photo]
    SELECTPHOTO --> UPLOADPREVIEW

    OPENFILES --> SELECTFILE[Select File]
    SELECTFILE --> UPLOADPREVIEW

    UPLOADPREVIEW --> ADDMOBILEMETA[Add Metadata<br/>Touch-Friendly Form]
    ADDMOBILEMETA --> UPLOADFILE[Upload File]
    UPLOADFILE --> UPLOADING[Show Upload Progress]
    UPLOADING --> UPLOADCOMPLETE[Upload Complete]
    UPLOADCOMPLETE --> END

    style START fill:#e1f5ff,stroke:#01579b,stroke-width:3px
    style END fill:#c8e6c9,stroke:#2e7d32,stroke-width:3px
    style CHECKSIZE fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style WARNSIZE fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    style RESPONSIVE fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    style DOCLIST fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
```

## First-Time User Onboarding Flow

```mermaid
graph TD
    START([User Opens App First Time]) --> WELCOME[Welcome Screen]

    WELCOME --> INTRO{Skip Tutorial?}
    INTRO -->|Skip| APISETUP
    INTRO -->|Take Tour| TOUR1[Tour Step 1:<br/>Upload Documents]

    TOUR1 --> TOUR2[Tour Step 2:<br/>Organize with Folders]
    TOUR2 --> TOUR3[Tour Step 3:<br/>Add Tags & Metadata]
    TOUR3 --> TOUR4[Tour Step 4:<br/>Search & Find]
    TOUR4 --> TOUR5[Tour Step 5:<br/>Download & Share]
    TOUR5 --> APISETUP[API Key Setup Screen]

    APISETUP --> ENTERAPI[Enter API Key]
    ENTERAPI --> VALIDATEAPI{Valid Key?}
    VALIDATEAPI -->|No| APIERROR[Error: Invalid API Key]
    APIERROR --> ENTERAPI
    VALIDATEAPI -->|Yes| SAVEAPI[Save API Key]

    SAVEAPI --> FIRSTLOGIN[First Login Successful]
    FIRSTLOGIN --> EMPTYSTATE[Empty State<br/>No Documents Yet]

    EMPTYSTATE --> ACTIONS[Show Quick Actions]
    ACTIONS --> QUICKSTART{What First?}

    QUICKSTART -->|Upload Document| FIRSTUPLOAD[Upload First Document Flow]
    QUICKSTART -->|Create Folder| FIRSTFOLDER[Create First Folder Flow]
    QUICKSTART -->|View Sample| SAMPLEDOCS[View Sample Documents]

    FIRSTUPLOAD --> UPLOADED[First Document Uploaded]
    UPLOADED --> CONGRATSMSG[Congratulations Message]

    FIRSTFOLDER --> FOLDERCREATED[First Folder Created]
    FOLDERCREATED --> CONGRATSMSG

    SAMPLEDOCS --> EXPLOREDOCS[Explore Sample Documents]
    EXPLOREDOCS --> CONGRATSMSG

    CONGRATSMSG --> NEXTSTEPS[Show Next Steps]
    NEXTSTEPS --> TIPS{Show Tips?}
    TIPS -->|Yes| TIP1[Tip: Use tags for organization]
    TIP1 --> TIP2[Tip: Search works instantly]
    TIP2 --> TIP3[Tip: Drag-drop to upload]
    TIP3 --> DASHBOARD[Go to Dashboard]
    TIPS -->|No| DASHBOARD

    DASHBOARD --> NORMUSE[Normal Application Use]
    NORMUSE --> END([Onboarding Complete])

    style START fill:#e1f5ff,stroke:#01579b,stroke-width:3px
    style END fill:#c8e6c9,stroke:#2e7d32,stroke-width:3px
    style CONGRATSMSG fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style VALIDATEAPI fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style APIERROR fill:#ffccbc,stroke:#d84315,stroke-width:2px
    style EMPTYSTATE fill:#e1bee7,stroke:#6a1b9a,stroke-width:2px
```

## User Flow Observations

### Upload Flow Key Points
- Multiple file selection methods (browse, drag-drop)
- Progressive disclosure (metadata optional, can be added later)
- Clear validation with helpful error messages
- Progress indication for large files
- Automatic retry on failure

### Search Flow Key Points
- Multiple entry points (header bar, search page)
- Live results as user types (debounced)
- Progressive filtering to refine results
- Quick actions from search results
- Path back to folder location

### Folder Management Key Points
- Visual folder tree for context
- Preview of full path before creation
- Validation prevents common errors
- Drag-drop for easy reorganization
- Confirmation on destructive actions

### Edit Metadata Flow Key Points
- Multiple entry points to editor
- Autocomplete for tags (reuse existing)
- Preview changes before saving
- Clear error messages with guidance
- Discard option to cancel changes

### Mobile Flow Key Points
- Touch-optimized UI components
- Swipe gestures for quick actions
- File size warnings on cellular
- Native share integration
- Camera upload for photos

### Onboarding Flow Key Points
- Optional tutorial (can skip)
- Interactive guided tour
- API key setup with validation
- Empty state with clear actions
- Helpful tips for new users

## Notes

- All flows include error handling and recovery
- User can cancel most operations
- Progress indication for long operations
- Confirmation required for destructive actions
- Mobile flows optimized for touch interaction
- Accessibility considered in all flows
