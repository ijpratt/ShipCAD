{#############################################################################################}
{    This code is distributed as part of the FREE!ship project. FREE!ship is an               }
{    open source surface-modelling program based on subdivision surfaces and intended for     }
{    designing ships.                                                                         }
{                                                                                             }
{    Copyright � 2005, by Martijn van Engeland                                                }
{    e-mail                  : Info@FREEship.org                                              }
{    FREE!ship project page  : https://sourceforge.net/projects/freeship                      }
{    FREE!ship homepage      : www.FREEship.org                                               }
{                                                                                             }
{    This program is free software; you can redistribute it and/or modify it under            }
{    the terms of the GNU General Public License as published by the                          }
{    Free Software Foundation; either version 2 of the License, or (at your option)           }
{    any later version.                                                                       }
{                                                                                             }
{    This program is distributed in the hope that it will be useful, but WITHOUT ANY          }
{    WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A          }
{    PARTICULAR PURPOSE. See the GNU General Public License for more details.                 }
{                                                                                             }
{    You should have received a copy of the GNU General Public License along with             }
{    this program; if not, write to the Free Software Foundation, Inc.,                       }
{    59 Temple Place, Suite 330, Boston, MA 02111-1307 USA                                    }
{                                                                                             }
{#############################################################################################}

unit FreeShipUnit;

interface

{$IFDEF LINUX}
   //do Linux-specific code here
{$ENDIF}
{$IFDEF MSWINDOWS}
   //do WIndows-specific code here
   uses SysUtils,// this declaration must be at the start, before the FreeGeometry unit
        Types,
        Forms,
        Controls,
        Windows,
        Dialogs,
        Classes,
        FreeVersionUnit,
        FasterList,
        FreeGeometry,
        FreeMatrices,
        Graphics,
        JPEG,
        FreeLanguageSupport,
        FreeControlPointFrm;
{$ENDIF}


// FREE!ship uses British imperial format, eg 1 long ton=2240 lbs


const FreeShipExtention           = '.fbm';                                                              // Default extention for hull model files
      SelectDistance              = 3;                                                                   // Max. distance in pixels between an item and the cursor in order to be selected
      Threshold                   = 3;                                                                   // The distance that the cursor has to be moved before a controlpoint starts moving
      FontheightFactor            = 140;                                                                 // used for calculating fontheight

type TFreePrecisionType           = (fpLow,fpMedium,fpHigh,fpVeryHigh);                                  // Precision of the ship-model
     TFreeIntersectionType        = (fiFree,fiStation,fiButtock,fiWaterline,fiDiagonal);                 // Different types of intersectionlines, stations, buttocks, waterlines and lines orientated in random planes
     TFreeModelView               = (mvPort,mvBoth);                                                     // Show half the hull or the entire hull
     TFreeEditMode                = (emSelectItems);                                                     // The program responds differnt to mouse actions depending on the editmode of the component
     TFreeHydrostaticType         = (fhShort,fhExtensive);                                               // Determines how calculations are performed: short, extensive etc.
     TFreeHydrostaticsMode        = (fhSingleCalculation,fhMultipleCalculations);                        // Used when creating hydrostatic reports
     TFreeHydrostaticsCalculation = (hcAll,hcVolume,hcMainframe,hcWaterline,hcSAC,hcLateralArea);        //
     TFreeHydrostaticsCalculate   = set of TFreeHydrostaticsCalculation;                                 // Set with all calculations to be performed
     TFreeShip                    = class;                                                               // to be declared later
     TFreeIntersection            = class;
     TFreeHydrostaticError        = (feNothingSubmerged,feMakingWater,feNotEnoughBuoyancy);              // Errors that may occur when calculating hydrostatics
     TFreeHydrostaticErrors       = set of TFreeHydrostaticError;
     TFreeHydrostaticCoeff        = (fcProjectSettings,fcActualData);
     TFreeHydrostaticsData        = record
                                       ModelMin,ModelMax       : T3DCoordinate;        // Min/max coordinates under given heelingangle and trim
                                       WlMin,WlMax             : T3DCoordinate;        // Min/max coordinates of the waterline
                                       SubMin,SubMax           : T3DCoordinate;        // Min/max extents of the submerged body
                                       WaterlinePlane          : T3DPlane;
                                       AbsoluteDraft           : TFloatType;           // Depth of the lowest point of the hull beneath the waterplane
                                       // The following properties are always calculated
                                       Volume                  : TFloatType;           // Displaced volume of the hull
                                       Displacement            : TFloatType;           // Displacement
                                       CenterOfBuoyancy        : T3DCoordinate;        // Center of gravity of displaced volume
                                       LCBPerc                 : TFloatType;
                                       LengthWaterline         : TFloatType;
                                       BeamWaterline           : TFloatType;
                                       BlockCoefficient        : TFloatType;           // BlockCoefficient
                                       WettedSurface           : TFloatType;
                                       Leak                    : T3DCoordinate;        // Coordinate encountered where the ship is making water
                                       // Mainframe properties
                                       Mainframearea           : TFloatType;
                                       MainFrameCOG            : T3DCoordinate;
                                       MainframeCoeff          : TFloatType;
                                       // Waterplane properties
                                       Waterplanearea          : TFloatType;
                                       WaterplaneCOG           : T3DCoordinate;
                                       WaterplaneEntranceAngle : TFloatType;
                                       WaterplaneCoeff         : TFloatType;
                                       WaterplaneMomInertia    : T2DCoordinate;
                                       // Stability data
                                       KMtransverse            : TFloatType;
                                       KMlongitudinal          : TFloatType;
                                       // Lateral area and center
                                       LateralArea             : TFloatType;
                                       LateralCOG              : T3DCoordinate;

                                       // Prismatic coefficient
                                       PrismCoefficient        : TFloatType;           // Prismatic coefficient
                                       VertPrismCoefficient    : TFloatType;
                                       // Sectional areas
                                       SAC                     : array of T2DCoordinate;
                                    end;
     TFreeCrosscurvesData         = record
                                       WaterlinePlane          : T3DPlane;
                                       AbsoluteDraft           : TFloatType;           // Depth of the lowest point of the hull beneath the waterplane
                                       // The following properties are always calculated
                                       Volume                  : TFloatType;           // Displaced volume of the hull
                                       Displacement            : TFloatType;           // Displacement
                                       CenterOfBuoyancy        : T3DCoordinate;        // Center of gravity of displaced volume
                                       // Stability data
                                       KNSinPhi                : TFloatType;
                                    end;
     TFreeDelftSeriesResistanceData=record
                                       StartSpeed        : TFloatType;
                                       EndSpeed          : TFloatType;
                                       StepSpeed         : TFloatType;
                                       Bwl               : TFloatType;
                                       Cp                : TFloatType;
                                       Displacement      : TFloatType;
                                       Draft             : TFloatType;
                                       DraftTotal        : TFloatType;
                                       KeelChordLength   : TFloatType;
                                       KeelArea          : TFloatType;
                                       LCB               : TFloatType;
                                       Lwl               : TFloatType;
                                       RudderChordLength : TFloatType;
                                       RudderArea        : TFloatType;
                                       Viscosity         : TFloatType;
                                       WettedSurface     : TFloatType;
                                       WlArea            : TFloatType;
                                       EstimateWetSurf   : boolean;
                                       Extract           : Boolean;
                                    end;
     TFreeKAPERResistanceData     = record
                                       Draft             : TFloatType;
                                       Lwl               : TFloatType;
                                       Bwl               : TFloatType;
                                       Cp                : TFloatType;
                                       Displacement      : TFloatType;
                                       LCB               : TFloatType;
                                       WettedSurface     : TFloatType;
                                       At_Ax             : TFloatType;
                                       EntranceAngle     : TFloatType;
                                       Extract           : Boolean;
                                    end;
     {---------------------------------------------------------------------------------------------------}
     {                                       TFreeUndoObject                                             }
     {                                                                                                   }
     {   TFreeUndoObject is an object class for undoing actions.                                         }
     {   It's function is very basic, just before each modification the file is saved to a the           }
     {   undo object rather then to a file. When the undo is called, the previous state will be          }
     {   read from the undo object and restored                                                          }
     {---------------------------------------------------------------------------------------------------}
     TFreeUndoObject        = class
                                 private
                                    FOwner                           : TFreeShip;
                                    FUndoText                        : string;
                                    FUndoData                        : TFreeFileBuffer;
                                    // some other data to be stored
                                    FFileChanged                     : Boolean;
                                    FFilenameSet                     : Boolean;
                                    FFilename                        : string;
                                    FEditMode                        : TFreeEditMode;
                                    FTime                            : TDateTime;
                                    FIsTempRedoObject                : Boolean;
                                    function FGetMemory:integer; // calculates the amount of bytes used for each undo object
                                    function FGetTime:string;
                                    function FGetUndoText:string;
                                 public
                                    procedure Accept;
                                    constructor Create(Owner:TFreeShip);
                                    procedure Delete;
                                    destructor Destroy;                    override;
                                    procedure Restore;
                                    property Memory         : integer read FGetMemory; // calculates the amount of bytes used for each undo object
                                    property Owner          : TFreeShip read FOwner;
                                    property Time           : String read FGetTime;
                                    property UndoData       : TFreeFileBuffer read FUndoData;
                                    property UndoText       : string read FGetUndoText;

                              end;
     {---------------------------------------------------------------------------------------------------}
     {                                       TFreeBackgroundImageData                                    }
     {                                                                                                   }
     {   Freeship can import a max. of three different background images that may be coupled either      }
     {   to the bodyplan, profile or planview. These images can be used to trace the lines of an         }
     {   hullform and are stored within the FREE!ship file.                                              }
     {---------------------------------------------------------------------------------------------------}
     TFreeBackgroundImageData=class
                                 private
                                    FOwner         : TFreeship;
                                    FAssignedView  : TFreeViewType;
                                    FImageData     : TJPEGImage;
                                    FQuality       : Integer;
                                    FOrigin        : TPoint;
                                    FScale         : TFloatType;
                                    FTransparent   : Boolean;
                                    FBlendingValue : Integer;
                                    FTransparentColor:TColor;
                                    FVisible       : Boolean;
                                    FTolerance     : Integer;
                                 public
                                    procedure Clear;
                                    constructor Create(Owner:TFreeship);
                                    destructor Destroy;              override;
                                    procedure LoadBinary(Source:TFreeFileBuffer);
                                    procedure SaveBinary(Destination:TFreeFileBuffer);
                                    procedure UpdateData(Viewport:TFreeViewport);
                                    procedure UpdateViews;
                                    property AssignedView      : TFreeViewType read FAssignedView;
                                    property BlendingValue     : Integer read FBlendingValue;
                                    property Image             : TJPEGImage read FImageData;
                                    property Origin            : TPoint read FOrigin;
                                    property Quality           : Integer read FQuality;
                                    property Scale             : TFloatType read FScale;
                                    property Tolerance         : integer read FTolerance;
                                    property Transparent       : Boolean read FTransparent;
                                    property TransparentColor  : TColor read FTransparentColor;
                              end;
     {---------------------------------------------------------------------------------------------------}
     {                                       TFreeHydrostaticCalc                                        }
     {                                                                                                   }
     {   TFreeHydrostaticCalc is an object class for hydrostatic calculations.                           }
     {   Each calculation has it's own draft, trim and angle of heel.                                    }
     {   Multiple calculations can be stored and then send to a report.                                  }
     {---------------------------------------------------------------------------------------------------}
     TFreeHydrostaticCalc   = class
                                 private
                                    FOwner                           : TFreeShip;
                                    // Input data for each calculation
                                    FHeelingAngle                    : TFloatType;
                                    FTrim                            : TFloatType;
                                    FDraft                           : TFloatType;
                                    // Calculation flags
                                    FCalculated                      : Boolean;
                                    FErrors                          : TFreeHydrostaticErrors;
                                    FHydrostaticType                 : TFreeHydrostaticType; // Determines how calculations are performed: short, extensive etc.
                                    // The following data is calculated
                                    FData                            : TFreeHydrostaticsData;
                                    FCalculations                    : TFreeHydrostaticsCalculate;
                                    FMainFrame                       : TFreeIntersection;
                                    function FGetErrorString:string;
                                    function FGetTrimAngle:TFloatType;
                                    function FGetWlPlane:T3DPlane;
                                    procedure FSetCalculated(val:Boolean);
                                    procedure FSetDraft(Val:TFloatType);
                                    procedure FSetErrors(val:TFreeHydrostaticErrors);
                                    procedure FSetHeelingAngle(Val:TFloatType);
                                    procedure FSetHydrostaticType(val:TFreeHydrostaticType);
                                    procedure FSetTrim(Val:TFloatType);
                                 public
                                    procedure   AddData(Strings:TStringlist;Mode:TFreeHydrostaticsMode;Separator:char); // Add calculated data to a stringlist to either show in a report or save to disc
                                    procedure   AddHeader(Strings:TStringlist);
                                    Procedure   AddFooter(Strings:TStringlist;Mode:TFreeHydrostaticsMode);
                                    function    Balance(Displacement:TFloatType;FreeToTrim:Boolean;var Output:TFreeCrosscurvesData):boolean;
                                    procedure   Calculate;                                               // The actual calculation of the hydrostatics finds place in this procedure
                                    procedure   CalculateVolume(WaterlinePlane:T3DPlane);
                                    procedure   Clear;
                                    constructor Create(Owner:TFreeShip);                                       virtual;
                                    destructor  Destroy;                                                       override;
                                    procedure   ShowData(Mode:TFreeHydrostaticsMode);
                                    property    Calculated           : Boolean read FCalculated write FSetCalculated;
                                    property    Calculations         : TFreeHydrostaticsCalculate read FCalculations write FCalculations;
                                    property    Data                 : TFreeHydrostaticsData read FData;
                                    property    Draft                : TFloatType read FDraft write FSetDraft;
                                    property    Errors               : TFreeHydrostaticErrors read FErrors write FSetErrors;
                                    property    ErrorString          : String read FGetErrorString;
                                    property    HeelingAngle         : TFloatType read FHeelingAngle write FSetHeelingAngle;
                                    property    HydrostaticType      : TFreeHydrostaticType read FHydrostaticType write FSetHydrostaticType; // Determines how calculations are performed: short, extensive etc.
                                    property    Owner                : TFreeShip read FOwner;
                                    property    Trim                 : TFloatType read FTrim write FSetTrim;
                                    property    TrimAngle            : TFloatType read FGetTrimAngle;
                                    property    WaterlinePlane       : T3DPLane read FGetWlPlane;
                              end;
     {---------------------------------------------------------------------------------------------------}
     {                                       TFreeIntersection                                           }
     {                                                                                                   }
     {   TFreeIntersection is a list of curves calculated from the intersection of a                     }
     {   ship hull (represented by a subdivision surface) and a plane.                                   }
     {   This plane can be a orthogonal plane (eg. stations, waterlines, buttocks) or a freely oriented  }
     {   3D plane (sent)                                                                                 }
     {---------------------------------------------------------------------------------------------------}
     TFreeIntersection      = class
                                 private
                                    FOwner                        : TFreeShip;
                                    FItems                        : TFasterList;
                                    FIntersectionType             : TFreeIntersectionType;
                                    FPlane                        : T3DPlane;
                                    FBuild                        : Boolean;
                                    FShowCurvature                : Boolean;
                                    FUseHydrostaticsSurfacesOnly  : boolean; // used for lateral area, mainframe and waterplane properties
                                    function    FGetColor:TColor;
                                    function    FGetPlane:T3DPlane;
                                    function    FGetCount:integer;
                                    function    FGetDescription:string;
                                    function    FGetItem(Index:integer):TFreeSpline;
                                    procedure   FSetBuild(Val:Boolean);
                                 public
                                    procedure   Add(Item:TFreeSpline);
                                    procedure   CalculateArea(Plane:T3DPlane;var Area:TFloatType;var COG:T3DCoordinate;var MomentOfInertia:T2DCoordinate);
                                    procedure   Clear;
                                    constructor Create(Owner:TFreeShip);
                                    procedure   CreateStarboardPart;       // Create the starboardhalf of the ship, for use in hydrostatic calculations
                                    procedure   Delete(Redraw:Boolean);
                                    procedure   DeleteItem(Item:TFreeSpline);
                                    destructor  Destroy;                                                       override;
                                    procedure   Draw(Viewport:TFreeViewport);
                                    procedure   DrawAll;
                                    procedure   Extents(Var Min,Max:T3DCoordinate);
                                    procedure   LoadBinary(Source:TFreeFileBuffer);
                                    procedure   Rebuild;
                                    procedure   SaveToDXF(Strings:TStringList);
                                    procedure   SaveBinary(Destination:TFreeFileBuffer);
                                    property    Build                : Boolean read FBuild write FSetBuild;
                                    property    Color                : TColor read FGetColor;
                                    property    Count                : integer read FGetCount;
                                    property    Description          : string read FGetDescription;
                                    property    IntersectionType     : TFreeIntersectionType read FIntersectionType write FIntersectionType;
                                    property    Items[index:integer] : TFreeSpline read FGetItem;
                                    property    Owner                : TFreeShip read FOwner;
                                    property    Plane                : T3DPlane read FGetPlane write FPlane;
                                    property    ShowCurvature        : Boolean read FShowCurvature write FShowCurvature;
                                    property    UseHydrostaticsSurfacesOnly:boolean read FUseHydrostaticsSurfacesOnly write FUseHydrostaticsSurfacesOnly;
                              end;
     {---------------------------------------------------------------------------------------------------}
     {                                           TFreeMarker                                             }
     {---------------------------------------------------------------------------------------------------}
     TFreeMarker            = class(TFreeSpline)
                                 private
                                    FVisible    : Boolean;
                                    FOwner      : TFreeShip;
                                    function FGetSelected:Boolean;
                                    procedure FSetSelected(val:Boolean);
                                 public
                                    procedure Clear;                                                        override;
                                    function  DistanceToCursor(X,Y:Integer;Viewport:TFreeViewport):integer; override;
                                    procedure Delete;
                                    procedure Draw(Viewport:TFreeViewport);                                 override;
                                    procedure LoadBinary(Source:TFreeFileBuffer);                           override;
                                    procedure SaveBinary(Destination:TFreeFileBuffer);                      override;
                                    property Owner       : TFreeShip read FOwner;
                                    property Selected    : Boolean read FGetSelected write FSetSelected;
                                    property Visible     : Boolean read FVisible write FVisible;
                              end;
     {---------------------------------------------------------------------------------------------------}
     {                                           TFreeFlowline                                           }
     {---------------------------------------------------------------------------------------------------}
     TFreeFlowline          = class
                                 private
                                    FProjectionPoint     : T2DCoordinate;
                                    FProjectionView      : TFreeViewType;
                                    FFlowLine            : TFreeSpline;
                                    FBuild               : Boolean;
                                    FOwner               : TFreeShip;
                                    FMethodNew:Boolean;
                                    function FGetColor:TColor;
                                    function FGetSelected:Boolean;
                                    function FGetVisible:Boolean;
                                    procedure FSetBuild(val:Boolean);
                                    procedure FSetSelected(val:Boolean);
                                 public
                                    procedure Clear;
                                    constructor Create(Owner:TFreeShip);
                                    procedure Delete;
                                    destructor Destroy;                                                       override;
                                    function  DistanceToCursor(X,Y:Integer;Viewport:TFreeViewport):integer;
                                    procedure Draw(Viewport:TFreeViewport);
                                    procedure LoadBinary(Source:TFreeFileBuffer);
                                    procedure Rebuild;
                                    procedure SaveBinary(Destination:TFreeFileBuffer);
                                    property Build       : Boolean read FBuild write FSetBuild;
                                    property Color       : TColor read FGetColor;
                                    property Owner       : TFreeShip read FOwner;
                                    property Selected    : Boolean read FGetSelected write FSetSelected;
                                    property Visible     : boolean read FGetvisible;
                              end;
     {---------------------------------------------------------------------------------------------------}
     {                                       TFreeVisibility                                             }
     {                                                                                                   }
     {   This object stores all visibility options for the hull                                          }
     {---------------------------------------------------------------------------------------------------}
     TFreeVisibility     = class(TPersistent)
                                 private
                                    FOwner                        : TFreeShip;
                                    FShowControlNet               : Boolean;
                                    FShowInteriorEdges            : Boolean;        // Show the surface edges
                                    FShowStations                 : Boolean;        // Show the calculated stations
                                    FShowButtocks                 : Boolean;        // Show the calculated Buttocks
                                    FShowWaterlines               : Boolean;        // Show the calculated Waterlines
                                    FShowDiagonals                : Boolean;        // Show the calculated Diagonals
                                    FModelView                    : TFreeModelView; // Show half or entire ship
                                    FShowNormals                  : Boolean;        // Show normals of selected surface patches
                                    FShowGrid                     : Boolean;        // Show the grid of intersections in the plan,profile and bodyplan view
                                    FShowMarkers                  : Boolean;
                                    FShowControlCurves            : boolean;
                                    FShowCurvature                : Boolean;
                                    FShowHydrostaticData          : boolean;
                                    FShowHydrostDisplacement      : boolean;
                                    FShowHydrostLateralArea       : boolean;
                                    FShowHydrostSectionalAreas    : boolean;
                                    FShowHydrostMetacentricHeight : boolean;
                                    FShowHydrostLCF               : boolean;
                                    FShowFlowlines                : Boolean;
                                    FCurvatureScale               : TFloatType;     // Scalefactor used to increase or decrease the size of the curvature plot
                                    FCursorIncrement              : TFloatType;     // Distance added when the active controlpoint is moved withe the arrow keys
                                    procedure FSetCursorIncrement(val:TFloatType);
                                    procedure FSetCurvatureScale(Val:TFloatType);
                                    procedure FSetShowButtocks(Val:Boolean);
                                    procedure FSetShowControlNet(Val:Boolean);
                                    procedure FSetShowCurvature(Val:Boolean);
                                    procedure FSetShowDiagonals(Val:Boolean);
                                    procedure FSetShowFlowlines(Val:Boolean);
                                    procedure FSetShowGrid(Val:Boolean);
                                    procedure FSetModelView(Val:TFreeModelView);
                                    procedure FSetShowInteriorEdges(Val:Boolean);
                                    procedure FSetShowMarkers(Val:Boolean);
                                    procedure FSetShowNormals(Val:Boolean);
                                    procedure FSetShowStations(Val:Boolean);
                                    procedure FSetShowWaterlines(Val:Boolean);
                                    procedure FSetShowControlCurves(Val:Boolean);
                                    procedure FSetShowHydrostaticData(Val:Boolean);
                                 public
                                    constructor Create(Owner:TFreeShip);
                                    procedure   Clear;
                                    procedure   DecreaseCurvatureScale;
                                    procedure   IncreaseCurvatureScale;
                                    procedure   LoadBinary(Source:TFreeFilebuffer);
                                    procedure   SaveBinary(Destination:TFreeFileBuffer);
                                    property    Owner                         : TFreeShip read FOwner write FOwner;
                                 published
                                    property    CursorIncrement               : TFloatType read FCursorIncrement write FSetCursorIncrement;
                                    property    CurvatureScale                : TFloatType read FCurvatureScale write FSetCurvatureScale;
                                    property    ModelView                     : TFreeModelView read FModelView write FSetModelView;
                                    property    ShowButtocks                  : boolean read FShowButtocks write FSetShowButtocks;
                                    property    ShowControlCurves             : boolean read FShowControlCurves write FSetShowControlCurves;
                                    property    ShowControlNet                : boolean read FShowControlNet write FSetShowControlNet;
                                    property    ShowCurvature                 : boolean read FShowCurvature write FSetShowCurvature;
                                    property    ShowDiagonals                 : boolean read FShowDiagonals write FSetShowDiagonals;
                                    property    ShowFlowlines                 : boolean read FShowFlowlines write FSetShowFlowlines;
                                    property    ShowGrid                      : boolean read FShowGrid write FSetShowGrid;
                                    property    ShowHydrostaticData           : boolean read FShowHydrostaticData write FSetShowHydrostaticData;
                                    property    ShowInteriorEdges             : boolean read FShowInteriorEdges write FSetShowInteriorEdges;
                                    property    ShowMarkers                   : boolean read FShowMarkers write FSetShowMarkers;
                                    property    ShowNormals                   : boolean read FShowNormals write FSetShowNormals;
                                    property    ShowStations                  : boolean read FShowStations write FSetShowStations;
                                    property    ShowWaterlines                : boolean read FShowWaterlines write FSetShowWaterlines;
                              end;
     {---------------------------------------------------------------------------------------------------}
     {                                       TFreeEdit                                                   }
     {                                                                                                   }
     {   Container class for all editing commandsns for the hull                                         }
     {---------------------------------------------------------------------------------------------------}
     TFreeEdit           = class
                                 private
                                    FOwner                        : TFreeShip;
                                    FRecentFiles                  : TStringList;
                                    function FGetRecentFile(Index:integer):string;
                                    function FGetRecentFileCount:integer;
                                 public
                                    procedure AddToRecentFiles(Filename:String);                            // Takes a filename and adds it to the list with recent files
                                    procedure BackgroundImage_Delete(Viewport:TFreeViewport);               // Delete the backgrundimage associated with this view
                                    procedure BackgroundImage_Open(Viewport:TFreeViewport);                 // browse for and open a backgroundimage
                                    constructor Create(Owner:TFreeShip);
                                    function  CreateRedoObject:TFreeUndoObject;                             // Creates redo data before an undo is done
                                    function  CreateUndoObject(UndoText:String;Accept:Boolean):TFreeUndoObject;// Creates undodata just prior to modifications
                                    procedure Curve_Add;                                                    // Add a new controlcurve
                                    destructor Destroy;                                         override;
                                    procedure Edge_Collapse;                                                // Remove an edge by replacing the two connected faces by one controlface
                                    procedure Edge_Connect;                                                 // Create a new edge by connection two controlpoints belonging to the same controlface
                                    procedure Edge_Crease;                                                  // Switch selected edges between normal or crease edges (knuckle lines)
                                    procedure Edge_Extrude;                                                 // Create new controlfaces by extruding selected boundary edges (eg edges with only 1 controlface connected to it)
                                    procedure Edge_Split;                                                   // Create new controlpoints by splitting an controledge into two.
                                    procedure Face_Assemble;
                                    procedure Face_DeleteNegative;                                          // Deletes all faces on the starboardside of the hull
                                    procedure Face_Flip;                                                    // Inverts the normal-direction of all selected controlfaces
                                    procedure Face_MirrorPlane;                                             // Mirrors all selected faces in a 3D plane
                                    procedure Face_New;                                                     // Creates a new controlface from the currently selected controlpoints
                                    procedure Face_Rotate;                                                  // Rotate selected faces around the X,Y and/or Z axis
                                    procedure Face_Scale;                                                   // Scale selected faces
                                    procedure Face_Move;                                                    // Move selected faces in X,Y and Z direction
                                    procedure File_ExportArchimedes;                                        // Exports stations to Archimedes or ArchimedesMB
                                    procedure File_ExportCoordinates;                                       // export the coordinates of all controlpoints to a textfile
                                    procedure File_ExportDXF_2DPolylines;                                   // Export all intersections to an individual DXF file as 2D polylines
                                    procedure File_ExportDXF_3DPolylines;                                   // Export all lines to a 3D DXF model as polylines
                                    procedure File_ExportDXF_Faces;                                         // Export all faces to a 3D DXF model
                                    procedure File_ExportFEF;                                               // Save to a Freeship Exchange Format (FEF) file
                                    procedure File_ExportGHS;                                               // Save ordinates to the GHS file format
                                    procedure File_ExportPart;                                              // Save part of the geometry to a file
                                    procedure File_ExportIGES;                                              // Save NURBS patches to an IGES file
                                    procedure File_Export_Michlet;                                          // Creates a file to be read by the CFD program Michlet
                                    procedure File_Import_MichletWaves;
                                    procedure File_ExportObj;                                               // Saves the model as a wavefront .Obj file
                                    procedure File_ExportOffsets;                                           // Exports all intersections to a textfile as 3D points
                                    procedure File_ExportSTL;                                               // Export the surface to a STL file
                                    procedure File_ImportCarene;                                            // imports a Carene XYZ file and creates a multichine boat with developable surfaces
                                    procedure File_ImportChines;                                            // Import chines from a textfile and fit a surface through them
                                    procedure File_ImportFEF;                                               // Import a Freeship Exchange Format (FEF) file
                                    procedure File_ImportHull;                   overload;virtual;          // Imports a file created with Carlssons's Hulls program
                                    procedure File_ImportHull(Filename:string;Quiet:Boolean);reintroduce;overload; // Imports a file created with Carlssons's Hulls program
                                    procedure File_ImportPart;                                              // Import a partfile and add it to the current geometry
                                    procedure File_ImportPolycad;                                           // Imports a PolyCad file
                                    procedure File_ImportSurface;                                           // Imports a number of curves and fits a surface
                                    Procedure File_ImportVRML;                                              // Import a VRML 1.0 file
                                    procedure File_Load;                         overload;virtual;          // Load a FREE!ship file by showing an opendialog
                                    procedure File_Load(filename:string);        reintroduce;overload;      // Loads the given filename quietly
                                    procedure File_Save;                                                    // save as FREE!ship file without prompting for a filename (must already been set)
                                    procedure File_SaveAs;                                                  // Ask for filename and save as FREE!ship file
                                    procedure Flowline_Add(Source:T2DCoordinate;View:TFreeviewType);
                                    procedure Geometry_AddCylinder;
                                    function  Hydrostatics_Calculate(Draft,AngleOfHeel,Trim:TFloatType):TFreeHydrostaticCalc;// Creates and calculates a hydrostatics calculation
                                    procedure Hydrostatics_Crosscurves;                                     // Opens the dialog to calculate crosscurves
                                    procedure Hydrostatics_Dialog;                                          // Opens the hydrostatics dialog and calculates hydrostatic data for a range of inputdata
                                    procedure ImportFrames;                                                 // Loads a bodyplane and tries to fit a surface to it
                                    function  Intersection_Add(IntType:TFreeIntersectionType;Distance:TFloatType):TFreeIntersection;// Add a new intersection at the specified location
                                    procedure Intersection_AddToList(Intersection:TFreeIntersection);       // Adds an intersection to the appropriate list
                                    procedure Intersection_Dialog;                                          // Pops up the dialog in whcih to add or delete stations, buttocks and waterlines
                                    procedure Layer_AutoGroup;                                              // All connected patches surrounded by crease edges are grouped together into a new layer
                                    procedure Layer_Develop;                                                // Developes all developable layers
                                    procedure Layer_Dialog;                                                 // Show layer dialog window
                                    procedure Layer_DeleteEmpty(Quiet:Boolean);                             // Delete all layers that are empty from the model
                                    function  Layer_New:TFreeSubdivisionLayer;                              // Add a new empty layer
                                    procedure Marker_Add(Marker:TFreeMarker);                               // Adds a marker to the list with markers
                                    procedure Marker_Delete;                                                // Delete all markers from the model
                                    procedure Marker_Import;                                                // Import markers from a textfile
                                    procedure Model_Check(ShowResult:Boolean);                              // Checks the surface for inconsistent normal directions and leaks
                                    function  Model_New:Boolean;                                            // Start a new model (with a predefined surface)
                                    procedure Model_LackenbyTransformation;                                 // Affine hullform transformation according to Lackenby
                                    procedure Model_Scale(ScaleVector:T3DCoordinate;OverrideLock,AdjustMarkers:Boolean); // Scale the entire model and all equivalent data such as stations etc.
                                    procedure Point_Collapse;                                               // Merge two selected edges by removing their common controlpoint.
                                    procedure Point_RemoveUnused;                                           // removes any unused points from the model
                                    procedure Point_InsertPlane;                                            // Finds all intersection of VISIBLE edges and a 3D plane, and inserts a point on each of these edges
                                    procedure Point_IntersectLayer;                                         // Calculates the intersection points of two layers
                                    procedure Point_Lock;                                                   // Locks all selected points
                                    function  Point_New:TFreeSubdivisionControlPoint;                       // Add a new point to the model with no edges/faces attached
                                    procedure Point_ProjectStraightLine;                                    // Project all selected points onto a straight line through the first and last selected points
                                    procedure Point_Unlock;                                                 // Unlocks all selected locked points
                                    procedure Point_UnlockAll;                                              // Unlocks all points
                                    function  ProceedWhenLockedPoints:Boolean;                              // Function that shows a warning when certain edit commands are invoked and the model contains locked points
                                    procedure Redo;                                                         // Restores the state of the model as it was after the previous undone
                                    procedure Resistance_Delft;                                             // Calculate resistance of yachts according to Delft systematic yacht series
                                    procedure Resistance_Kaper;                                             // Calculate resistance of slender hulls (canoes) according to John Winters
                                    procedure Selection_Clear;                                              // Deselect all selected items at once
                                    procedure Selection_Delete;                                             // Delete all selected items
                                    procedure Selection_SelectAll;                                          // Select all visible items
                                    procedure Undo;                                                         // Restores the state of the model as it was before the last modification
                                    procedure Undo_Clear;                                                   // Clear the undo history
                                    procedure Undo_ShowHistory;                                             // Show the undo history
                                    property  Owner                     : TFreeShip read FOwner write FOwner;
                                    property  RecentFile[index:integer] : string read FGetRecentFile;       // retrieve a filename from the recently used file list
                                    property  RecentFileCount           : integer read FGetRecentFileCount; // The number of files in the recently used file list
                              end;
     {---------------------------------------------------------------------------------------------------}
     {                                       TFreePreferences                                            }
     {                                                                                                   }
     {   Container class for all program settings                                                        }
     {---------------------------------------------------------------------------------------------------}
     TFreePreferences       = class(TPersistent)
                                 private
                                    FOwner                     : TFreeShip;
                                    FPointSize                 : integer; // Half width of controlpoints in pixels when drawn on screen
                                    // Colors
                                    FButtockColor              : TColor;
                                    FWaterlineColor            : TColor;
                                    FStationColor              : TColor;
                                    FDiagonalColor             : TColor;
                                    FEdgeColor                 : TColor;   // Color of normal edges
                                    FCreaseColor               : TColor;   // color of crease edges
                                    FCreaseEdgeColor           : TColor;   // color of crease control-edges
                                    FGridColor                 : TColor;   // Color of gridlines
                                    FGridFontColor             : TColor;   // Color of font with gridlines
                                    FCreasePointColor          : TColor;   // Color of crease vertices
                                    FRegularPointColor         : TColor;   //
                                    FCornerPointColor          : TColor;   // Color of cornerpoints and points with at least 3 crease edges
                                    FDartPointColor            : TColor;   //
                                    FSelectColor               : TColor;   // Color of selected items
                                    FLayerColor                : TColor;   // Default color for new layers
                                    FNormalColor               : TColor;   // color of surface normals
                                    FUnderWaterColor           : TColor;   // Default color used for shading underwaterpart of the vessel
                                    FViewportColor             : TColor;
                                    FLeakPointColor            : TColor;
                                    FMarkerColor               : TColor;
                                    FCurvaturePlotColor        : TColor;
                                    FControlCurveColor         : TColor;
                                    FHydrostaticsFontColor     : TColor;
                                    FZebraStripeColor          : TColor;
                                    FOpenDirectory             : string;   // Default directory to open existing files
                                    FSaveDirectory             : string;   // Default directory to save files
                                    FImportDirectory           : string;   // Default directory to import files
                                    FExportDirectory           : string;   // Default directory to export files
                                    FLanguageFile              : String;
                                    FMaxUndoMemory             : Integer;  // Max. amount of allowable undo memory in megabytes
                                    function FGetExportDirectory:string;
                                    function FGetImportDirectory:string;
                                    function FGetOpenDirectory:string;
                                    function FGetSaveDirectory:string;
                                    procedure FSetViewportColor(Val:TColor);
                                 public
                                    procedure   Clear;
                                    constructor Create(Owner:TFreeShip);
                                    procedure   Edit;
                                    procedure   Load;
                                    procedure   ResetColors;
                                    procedure   Save;
                                    property    Owner                : TFreeShip read FOwner write FOwner;
                                 published
                                    // General options
                                    property PointSize               : integer read FPointSize write FPointSize;
                                    // Color settings
                                    property ButtockColor            : TColor read FButtockColor write FButtockColor;
                                    property ControlCurveColor       : TColor read FControlCurveColor write FControlCurveColor;
                                    property CornerPointColor        : TColor read FCornerPointColor write FCornerPointColor;
                                    property CreaseColor             : TColor read FCreaseColor write FCreaseColor;
                                    property CreaseEdgeColor         : TColor read FCreaseEdgeColor write FCreaseEdgeColor;
                                    property CurvaturePlotColor      : TColor read FCurvaturePlotColor write FCurvaturePlotColor;
                                    property DiagonalColor           : TColor read FDiagonalColor write FDiagonalColor;
                                    property GridColor               : TColor read FGridColor write FGridColor;
                                    property GridFontColor           : TColor read FGridFontColor write FGridFontColor;
                                    property HydrostaticsFontColor   : TColor read FHydrostaticsFontColor write FHydrostaticsFontColor;
                                    property ImportDirectory         : string read FGetImportDirectory write FImportDirectory;
                                    property EdgeColor               : TColor read FEdgecolor write FEdgeColor;
                                    property ExportDirectory         : string read FGetExportDirectory write FExportDirectory;
                                    property CreasePointColor        : TColor read FCreasePointColor write FCreasePointColor;
                                    property LanguageFile            : string read FLanguageFile write FLanguageFile;
                                    property LayerColor              : TColor Read FLayerColor Write FLayerColor;
                                    property LeakPointColor          : TColor read FLeakPointColor write FLeakPointColor;
                                    property MarkerColor             : TColor Read FMarkerColor Write FMarkerColor;
                                    property MaxUndoMemory           : Integer read FMaxUndoMemory write FMaxUndoMemory;
                                    property NormalColor             : TColor read FNormalColor write FNormalColor;
                                    property OpenDirectory           : string read FGetOpenDirectory write FOpenDirectory;
                                    property SaveDirectory           : string read FGetSaveDirectory write FSaveDirectory;
                                    property StationColor            : TColor read FStationColor write FStationColor;
                                    property UnderWaterColor         : TColor read FUnderWaterColor write FUnderWaterColor;
                                    property RegularPointColor       : TColor read FRegularPointColor write FRegularPointColor;
                                    property DartPointColor          : TColor read FDartPointColor write FDartPointColor;
                                    property SelectColor             : TColor read FSelectColor write FSelectColor;
                                    property ViewportColor           : TColor read FViewportColor write FSetViewportColor;
                                    property WaterlineColor          : TColor read FWaterlineColor write FWaterlineColor;
                                    property ZebraStripeColor        : TColor read FZebraStripeColor write FZebraStripeColor;
                              end;

     {---------------------------------------------------------------------------------------------------}
     {                                       TFreeProjectSettings                                        }
     {                                                                                                   }
     {   Container class for project settings for each projecttl                                         }
     {---------------------------------------------------------------------------------------------------}
     TFreeProjectSettings   = class
                                 private
                                    FOwner                        : TFreeShip;
                                    FMainparticularsHasBeenset    : boolean;     // Flag to check if the main particulars have been set before hydrostatic calculationss are being performed
                                    FDisableModelCheck            : boolean;     // Disable the automatic checking of the surface
                                    FProjectAppendageCoefficient  : TFloatType;
                                    FProjectBeam                  : TFloatType;
                                    FProjectDraft                 : TFloatType;
                                    FProjectLength                : TFloatType;
                                    FProjectWaterDensity          : TFloatType;
                                    FProjectMainframeLocation     : TFloatType;
                                    FUseDefaultMainframeLocation  : Boolean;     // If set to true, the mainframe location is set to 0.5*project length, if false then value in FProjectMainframeLocation is used
                                    FProjectName                  : string;
                                    FProjectDesigner              : string;
                                    FProjectComment               : string;
                                    FProjectFileCreatedBy         : string;
                                    FProjectShadeUnderwaterShip   : Boolean;
                                    FSavePreview                  : Boolean;
                                    FProjectUnderWaterColor       : TColor;
                                    FProjectUnits                 : TFreeUnitType;
                                    FProjectSimplifyIntersections : boolean;
                                    FFreeHydrostaticCoefficients  : TFreeHydrostaticCoeff;
                                    // General hydrostatics calculation settings
                                    FStartDraft                   : TFloatType;
                                    FEndDraft                     : TFloatType;
                                    FDraftStep                    : TFloatType;
                                    FTrim                         : TFloatType;
                                    // crosscurves settings
                                    FDisplacements                : TFloatArray;
                                    FNoDisplacements              : integer;
                                    FMinimumDisplacement          : TFloatType;
                                    FMaximumDisplacement          : TFloatType;
                                    FDisplIncrement               : TFloatType;
                                    FUseDisplIncrements           : boolean;
                                    FNoAngles                     : Integer;
                                    FAngles                       : TFloatArray;
                                    FNoStabTrims                  : Integer;
                                    FStabTrims                    : TFloatArray;
                                    FFreeTrim                     : Boolean;
                                    FVCG                          : TFloatType;

                                    procedure FSetFreeHydrostaticCoefficients(val:TFreeHydrostaticCoeff);
                                    procedure FSetDisableModelCheck(Val:Boolean);
                                    function  FGetProjectMainframeLocation:TFloatType;
                                    procedure FSetProjectAppendageCoefficient(Val:TFloatType);
                                    procedure FSetProjectBeam(Val:TFloatType);
                                    procedure FSetProjectComment(Val:string);
                                    procedure FSetProjectDraft(Val:TFloatType);
                                    procedure FSetProjectFileCreatedBy(Val:string);
                                    procedure FSetProjectLength(Val:TFloatType);
                                    procedure FSetProjectMainframeLocation(val:TFloatType);
                                    procedure FSetProjectName(Val:string);
                                    procedure FSetProjectDesigner(Val:string);
                                    procedure FSetProjectShadeUnderwaterShip(Val:Boolean);
                                    procedure FSetProjectSimplifyIntersections(val:Boolean);
                                    procedure FSetProjectUnderWaterColor(Val:TColor);
                                    procedure FSetProjectUnits(Val:TFreeUnitType);
                                    procedure FSetProjectWaterDensity(Val:TFloatType);
                                    procedure FSetSavePreview(val:Boolean);
                                    procedure FSetStartDraft(Val:TFloatType);
                                    procedure FSetEndDraft(Val:TFloatType);
                                    procedure FSetDraftStep(Val:TFloatType);
                                    procedure FSetTrim(Val:TFloatType);
                                    procedure FSetUseDefaultMainframeLocation(Val:Boolean);
                                 public
                                    procedure Clear;
                                    constructor Create(Owner:TFreeShip);
                                    procedure Edit;                              // User input of mainparticulars and project setting
                                    procedure LoadBinary(Source:TFreeFilebuffer;Image:TJPegImage);overload;virtual;
                                    procedure SaveBinary(Destination:TFreeFileBuffer);
                                    property  DisableModelCheck            : boolean read FDisableModelCheck write FSetDisableModelCheck;
                                    property  Hydrostatics_Startdraft      : TFloatType read FStartDraft write FSetStartDraft;
                                    property  Hydrostatics_EndDraft        : TFloatType read FEndDraft write FSetEndDraft;
                                    property  Hydrostatics_DraftStep       : TFloatType read FDraftStep write FSetDraftStep;
                                    property  Hydrostatics_Trim            : TFloatType read FTrim write FSetTrim;
                                    property  MainparticularsHasBeenset    : boolean read FMainparticularsHasBeenset;
                                    property  Owner                        : TFreeShip read FOwner write FOwner;
                                    property  ProjectAppendageCoefficient  : TFloatType read FProjectAppendageCoefficient write FSetProjectAppendageCoefficient;
                                    property  ProjectBeam                  : TFloatType read FProjectBeam write FSetProjectBeam;
                                    property  ProjectCoefficients          : TFreeHydrostaticCoeff read FFreeHydrostaticCoefficients write FSetFreeHydrostaticCoefficients;
                                    property  ProjectComment               : string read FProjectComment write FSetProjectComment;
                                    property  ProjectDraft                 : TFloatType read FProjectDraft write FSetProjectDraft;
                                    property  ProjectFileCreatedBy         : string read FProjectFileCreatedBy write FSetProjectFileCreatedBy;
                                    property  ProjectLength                : TFloatType read FProjectLength write FSetProjectLength;
                                    property  ProjectMainframeLocation     : TFloatType read FGetProjectMainframeLocation write FSetProjectMainframeLocation;
                                    property  ProjectName                  : string read FProjectName write FSetProjectName;
                                    property  ProjectDesigner              : string read FProjectDesigner write FSetProjectDesigner;
                                    property  ProjectShadeUnderwaterShip   : boolean read FProjectShadeUnderwaterShip write FSetProjectShadeUnderwaterShip;
                                    property  ProjectSimplifyIntersections : boolean read FProjectSimplifyIntersections write FSetProjectSimplifyIntersections;
                                    property  ProjectUnderWaterColor       : TColor read FProjectUnderWaterColor write FSetProjectUnderWaterColor;
                                    property  ProjectUnits                 : TFreeUnitType read FProjectUnits write FSetProjectUnits;
                                    property  ProjectWaterDensity          : TFloatType read FProjectWaterDensity write FSetProjectWaterDensity;
                                    property  SavePreview                  : Boolean read FSavePreview write FSetSavePreview;
                                    property  UseDefaultMainframeLocation  : boolean read FUseDefaultMainframeLocation write FSetUseDefaultMainframeLocation;
                              end;
     {---------------------------------------------------------------------------------------------------}
     {                                       TFreeShip                                                   }
     {                                                                                                   }
     {   TFreeShip is the actual component used for modelling and representing the ship                  }
     {---------------------------------------------------------------------------------------------------}
      TFreeShip             = class(TComponent)
                                 private     { Private declarations }
                                    FViewports                 : TFasterList;                                              // List containing all viewports associated with the hullform
                                    FPrecision                 : TFreePrecisionType;
                                    FFileVersion               : TFreeFileVersion;
                                    FEditMode                  : TFreeEditMode;                                            // The component has different edit-modes which determine how the program responds to mouse-events
                                    FPreferences               : TFreePreferences;
                                    FActiveControlPoint        : TFreeSubdivisionControlPoint;                             // The last selected controlpoint (still selected)
                                    FFileChanged               : boolean;                                                  // Flag to keep track of modifications to the file
                                    FSurface                   : TFreeSubdivisionSurface;
                                    FFilename                  : string;                                                   // Filename of the current project;
                                    FEdit                      : TFreeEdit;                                                // Containerclass for all editing commands
                                    FStations                  : TFasterList;
                                    FButtocks                  : TFasterList;
                                    FWaterlines                : TFasterList;
                                    FDiagonals                 : TFasterList;
                                    FMarkers                   : TFasterList;
                                    FBackgroundImages          : TFasterList;
                                    FFlowLines                 : TFasterList;
                                    FSelectedFlowlines         : TFasterList;
                                    FSelectedMarkers           : TFasterList;
                                    FVisibility                : TFreeVisibility;
                                    FOnFileChanged             : TNotifyEvent;
                                    FOnUpdateUndoData          : TNotifyEvent;
                                    FOnUpdateRecentFileList    : TNotifyEvent;
                                    FOnChangeCursorIncrement   : TNotifyEvent;
                                    FOnUpdateGeometryInfo      : TNotifyEvent;         // This event is raised whenever items are added or deleted from the surface
                                    FFreeLinesplanFrme         : TFrame;
                                    FFilenameSet               : Boolean; // Flag to determine if the filename already has been set
                                    // The folowing private variables are for moving controlpoints with the mouse
                                    FCurrentlyMoving           : boolean;
                                    FPointHasBeenMoved         : boolean;
                                    FStopAskingForFileVersion  : Boolean;
                                    FPrevCursorPosition        : TPoint;
                                    FControlpointForm          : TFreeControlPointForm; // form for manual adjustment of controlpoints
                                    FIntersectionDialog        : TForm;                 // Dialog containing intersectionlines
                                    FProjectSettings           : TFreeProjectSettings;
                                    FHydrostaticCalculations   : TFasterList;          // List containing all hydrostatic calculations
                                    FUndoObjects               : TFasterList;
                                    FUndoPosition              : Integer;              // Index of the current undo object
                                    FPreviousUndoPosition      : Integer;
                                    FResistanceDelftData       : TFreeDelftSeriesResistanceData;
                                    FResistanceKaperData       : TFreeKAPERResistanceData;
                                    FDesignHydrostatics        : TFreeHydrostaticCalc; // This object calculates hydrostatic data to draw in the viewports
                                    procedure FBuildValidFrameTable(Destination:TFasterList;CloseAtDeck:Boolean); // Assembles all stations and builds a 2D bodyplan for export to other calculating programs
                                    function  FGetActiveLayer:TFreeSubdivisionlayer;
                                    function  FGetBackgroundImage(Index:Integer):TFreeBackgroundImageData;
                                    function  FGetBuild:Boolean;
                                    function  FGetButtock(Index:integer):TFreeIntersection;
                                    function  FGetControlCurve(Index:integer):TFreeSubdivisionControlCurve;
                                    function  FGetDiagonal(Index:integer):TFreeIntersection;
                                    function  FGetFlowline(Index:integer):TFreeFlowline;
                                    function  FGetFilename:string;
                                    function  FGetHydrostaticCalculation(Index:integer):TFreeHydrostaticCalc;
                                    function  FGetNumberOfLayers:integer;
                                    function  FGetLayer(Index:integer):TFreeSubdivisionLayer;
                                    function  FGetMarker(Index:integer):TFreeMarker;
                                    function  FGetNumberofBackgroundImages:Integer;
                                    function  FGetNumberOfButtocks:integer;
                                    function  FGetNumberOfControlCurves:integer;
                                    function  FGetNumberOfDiagonals:integer;
                                    function  FGetNumberOfFlowLines:Integer;
                                    function  FGetNumberOfHydrostaticCalculations:integer;
                                    function  FGetNumberOfLockedPoints:Integer;
                                    function  FGetNumberOfMarkers:integer;
                                    function  FGetNumberOfStations:integer;
                                    function  FGetNumberOfViewports:integer;
                                    function  FGetNumberOfWaterlines:integer;
                                    function  FGetOnChangeActiveLayer:TChangeActiveLayerEvent;
                                    function  FGetOnChangeLayerData:TNotifyEvent;
                                    function  FGetOnSelectItem:TNotifyEvent;
                                    function  FGetSelectedControlPoint(Index:integer):TFreeSubdivisionControlPoint;
                                    function  FGetSelectedControlEdge(Index:integer):TFreeSubdivisionControlEdge;
                                    function  FGetSelectedControlCurve(Index:integer):TFreeSubdivisionControlCurve;
                                    function  FGetSelectedControlFace(Index:integer):TFreeSubdivisionControlFace;
                                    function  FGetSelectedFlowline(index:Integer):TFreeFlowline;
                                    function  FGetSelectedMarker(index:Integer):TFreeMarker;
                                    function  FGetStation(Index:integer):TFreeIntersection;
                                    function  FGetUndoCount:integer;
                                    function  FGetUndoMemory:integer;
                                    function  FGetUndoObject(Index:integer):TFreeUndoObject;
                                    function  FGetViewport(Index:integer):TFreeViewport;
                                    function  FGetWaterline(Index:integer):TFreeIntersection;
                                    procedure FSetActiveControlPoint(Val:TFreeSubdivisionControlPoint);
                                    procedure FSetActiveLayer(Val:TFreeSubdivisionLayer);
                                    procedure FSetBuild(Val:Boolean);
                                    procedure FSetEditMode(Val:TFreeEditMode);
                                    procedure FSetFileChanged(Val:Boolean);
                                    procedure FSetFileName(Val:string);
                                    procedure FSetFileVersion(Val:TFreeFileVersion);
                                    function  FGetNumberOfSelectedControlCurves:integer;
                                    function  FGetNumberOfSelectedControlEdges:integer;
                                    function  FGetNumberOfSelectedControlFaces:integer;
                                    function  FGetNumberOfSelectedControlPoints:integer;
                                    function  FGetNumberOfselectedFlowlines:Integer;
                                    function  FGetNumberOfSelectedLockedPoints:integer;
                                    function  FGetNumberOfselectedMarkers:Integer;
                                    procedure FSetOnChangeActiveLayer(val:TChangeActiveLayerEvent);
                                    procedure FSetOnChangeLayerData(Val:TNotifyEvent);
                                    procedure FSetOnSelectItem(Val:TNotifyEvent);
                                    procedure FSetPrecision(Val:TFreePrecisionType);
                                    function  FGetPreview:TJPEGImage;
                                 protected   { Protected declarations }
                                 public      { Public declarations }
                                    procedure   AddViewport(Viewport:TFreeViewport);                                       // Add a viewport to the list of viewports connected to the model
                                    function    AdjustMarkers:Boolean;
                                    procedure   Clear;
                                    procedure   ClearUndo;
                                    constructor Create(AOwner:TComponent);                                     override;
                                    procedure   CreateOutputHeader(CalcHeader:string;Strings:TStrings);                                      // Creates a header with all relevant project data
                                    procedure   DeleteViewport(Viewport:TFreeViewport);                                    // Delete a viewport from the list of viewports connected to the model
                                    destructor  Destroy;                                                       override;
                                    procedure   Draw;
                                    procedure   DrawToViewport(Viewport:TFreeViewport);
                                    procedure   Extents(Var Min,Max:T3DCoordinate);                                        // calculate the bounding box coordinates of the model
                                    function    FindLowestHydrostaticsPoint:TFloatType;
                                    procedure   ImportChines(Np:Integer;Chines:TFasterList);                               // imports a number of longitudinally lines and creates developable surfaces between each two subsequent chines
                                    Procedure   LoadBinary(Source:TFreeFileBuffer);
                                    procedure   LoadPreview(Filename:string;Image:TJPegImage);                             // loads the preview image from a file
                                    procedure   RebuildModel;                                                              // Force to rebuild the entire ship and recalculate all data
                                    procedure   Redraw;                                                                    // Redraws the model on all viewports
                                    Procedure   SaveBinary(Destination:TFreeFileBuffer);
                                    procedure   SavePart(Faces:TFasterList);
                                    procedure   SubmergedHullExtents(Wlplane:T3DPlane;var Min,Max:T3DCoordinate);
                                    procedure   KeyUp(Viewport:TfreeViewport;var Key: Word;Shift: TShiftState);
                                    procedure   MouseDown(Viewport:TFreeViewport;Button:TMouseButton;Shift:TShiftState;X,Y:integer;var ItemSelected:Boolean);
                                    procedure   MouseMove(Viewport:TFreeViewport;Shift:TShiftState;X,Y:integer);
                                    procedure   MouseUp(Viewport:TFreeViewport;Shift:TShiftState;X,Y:integer);
                                    property    ActiveControlPoint                     : TFreeSubdivisionControlPoint read FActiveControlPoint write FSetActiveControlPoint;
                                    property    ActiveLayer                            : TFreeSubdivisionLayer read FGetActiveLayer write FSetActiveLayer;
                                    property    BackgroundImage[index:Integer]         : TFreeBackgroundImageData read FGetBackgroundImage;
                                    property    Build                                  : Boolean read FGetBuild write FSetBuild;
                                    property    Buttock[index:integer]                 : TFreeIntersection read FGetButtock;
                                    property    ControlCurve[index:integer]            : TFreeSubdivisionControlCurve read FGetControlCurve;
                                    property    ControlpointForm                       : TFreeControlPointForm read FControlpointForm; // Pointer to form for manual adjustment of controlpoints
                                    property    Diagonal[index:integer]                : TFreeIntersection read FGetDiagonal;
                                    property    Edit                                   : TFreeEdit read FEdit;                      // Containerclass for all editing commands
                                    property    EditMode                               : TFreeEditMode read FEditMode write FSetEditMode;
                                    property    FilenameSet                            : boolean read FFilenameSet write FFilenameSet;
                                    property    Flowline[index:integer]                : TFreeFlowline read FGetFlowline;
                                    property    HydrostaticCalculation[index:integer]  : TFreeHydrostaticCalc read FGetHydrostaticCalculation;
                                    property    Layer[index:integer]                   : TFreeSubdivisionLayer read FGetLayer;
                                    property    Marker[index:integer]                  : TFreeMarker read FGetMarker;
                                    property    NumberofBackgroundImages               : integer read FGetNumberofBackgroundImages;
                                    property    NumberofButtocks                       : integer read FGetNumberOfButtocks;
                                    property    NumberOfControlCurves                  : integer read FGetNumberOfControlCurves;
                                    property    NumberofDiagonals                      : integer read FGetNumberOfDiagonals;
                                    property    NumberOfHydrostaticCalculations        : integer read FGetNumberOfHydrostaticCalculations;
                                    property    NumberOfLayers                         : integer read FGetNumberOfLayers;
                                    property    NumberOfLockedPoints                   : integer read FGetNumberOfLockedPoints;
                                    property    NumberofMarkers                        : integer read FGetNumberOfMarkers;
                                    property    NumberOfFlowLines                      : integer read FGetNumberOfFlowLines;
                                    property    NumberOfSelectedControlCurves          : integer read FGetNumberOfSelectedControlCurves;
                                    property    NumberOfSelectedControlEdges           : integer read FGetNumberOfSelectedControlEdges;
                                    property    NumberOfSelectedControlFaces           : integer read FGetNumberOfSelectedControlFaces;
                                    property    NumberOfSelectedControlPoints          : integer read FGetNumberOfSelectedControlPoints;
                                    property    NumberOfselectedFlowlines              : integer read FGetNumberOfselectedFlowlines;
                                    property    NumberOfSelectedLockedPoints           : integer read FGetNumberOfSelectedLockedPoints;
                                    property    NumberOfselectedMarkers                : integer read FGetNumberOfselectedMarkers;
                                    property    NumberofStations                       : integer read FGetNumberOfStations;
                                    property    NumberOfViewports                      : integer read FGetNumberOfViewports;
                                    property    NumberofWaterlines                     : integer read FGetNumberOfWaterlines;
                                    property    OnChangeActiveLayer                    : TChangeActiveLayerEvent read FGetOnChangeActiveLayer write FSetOnChangeActiveLayer;
                                    property    OnChangeLayerData                      : TNotifyEvent read FGetOnChangeLayerData write FSetOnChangeLayerData;
                                    property    OnSelectItem                           : TNotifyEvent read FGetOnSelectItem write FSetOnSelectItem;
                                    property    SelectedControlCurve[index:integer]    : TFreeSubdivisionControlCurve read FGetSelectedControlCurve;
                                    property    SelectedControlPoint[index:integer]    : TFreeSubdivisionControlPoint read FGetSelectedControlPoint;
                                    property    SelectedControlEdge[index:integer]     : TFreeSubdivisionControlEdge read FGetSelectedControlEdge;
                                    property    SelectedControlFace[index:integer]     : TFreeSubdivisionControlFace read FGetSelectedControlFace;
                                    property    SelectedFlowline[index:integer]        : TFreeFlowline read FGetSelectedFlowline;
                                    property    SelectedMarker[index:integer]          : TFreeMarker read FGetSelectedMarker;
                                    property    Station[index:integer]                 : TFreeIntersection read FGetStation;
                                    property    StopAskingForFileVersion               : boolean read FStopAskingForFileVersion write FStopAskingForFileVersion;
                                    property    UndoCount                              : integer read FGetUndoCount;
                                    property    UndoMemory                             : integer read FGetUndoMemory; // amount of memory used by all undoobjects
                                    property    UndoObject[index:integer]              : TFreeUndoObject read FGetUndoObject;
                                    property    UndoPosition                           : integer read FUndoPosition;
                                    property    Viewport[index:integer]                : TFreeViewport read FGetViewport;
                                    property    Waterline[index:integer]               : TFreeIntersection read FGetWaterline;
                                    property    Surface                                : TFreeSubdivisionSurface read FSurface;
                                 published   { Published declarations }
                                    property    FileChanged                            : boolean read FFileChanged write FSetFileChanged;
                                    property    Filename                               : string read FGetFilename write FSetFileName;
                                    property    FileVersion                            : TFreeFileVersion read FFileVersion write FSetFileVersion;
                                    property    LinesplanFrame                         : TFrame read FFreeLinesplanFrme write FFreeLinesplanFrme;
                                    property    OnChangeCursorIncrement                : TNotifyEvent read FOnChangeCursorIncrement write FOnChangeCursorIncrement;
                                    property    OnFileChanged                          : TNotifyEvent read FOnFileChanged write FOnFileChanged;
                                    property    OnUpdateGeometryInfo                   : TNotifyEvent read FOnUpdateGeometryInfo write FOnUpdateGeometryInfo;
                                    property    OnUpdateRecentFileList                 : TNotifyEvent read FOnUpdateRecentFileList write FOnUpdateRecentFileList;
                                    property    OnUpdateUndoData                       : TNotifyEvent read FOnUpdateUndoData write FOnUpdateUndoData;
                                    property    Precision                              : TFreePrecisionType read FPrecision write FSetPrecision;
                                    property    Preferences                            : TFreePreferences read FPreferences;
                                    property    ProjectSettings                        : TFreeProjectSettings read FProjectSettings;
                                    property    Visibility                             : TFreeVisibility read FVisibility;
                              end;

// function to find the corresponding water viscosity based on the density
function FindWaterViscosity(Density:TFloatType;Units:TFreeUnitType):TFloatType;

procedure Register;

implementation

uses Math,
     FreeIGESUnit,
     FreeHydrostaticsDlg,
     FreeIntersectionDlg,
     FreeNewModelDlg,
     FreeExtrudeDlg,
     FreeProjectSettingsDlg,
     FreeRotateDlg,
     FreeHydrostaticsFrm,
     FreePreferencesDlg,
     FreeExpanedPlatesDlg,
     FreeLinesplanFrm,
     FreeLinesplanFrme,
     FreeInsertPlaneDlg,
     FreeMichletOutputDlg,
     FreeResistance_KaperDlg,
     FreeResistance_DelftDlg,
     FreeSelectLayersDlg,
     FreeMirrorPlaneDlg,
     Free2DDXFExportDlg,
     FreeLackenbyDlg,
     FreeIntersectLayerDlg,
     FreeUndoHistoryDlg,
     FreeCylinderDlg,
     FreeCrosscurvesDlg,
     FreeLayerDlg;

// function to find the corresponding water viscosity based on the density
function FindWaterViscosity(Density:TFloatType;Units:TFreeUnitType):TFloatType;
var TmpDensity:double;
begin
   if Units=fuMetric then
   begin
      Result:=1.13902+((Density-0.999)/(1.0259-0.999))*(1.18831-1.13902);
   end else
   begin
     // convert to metric
     TmpDensity:=Density/WeightConversionFactor;
     Result:=1.13902+((TmpDensity-0.999)/(1.0259-0.999))*(1.18831-1.13902);
     Result:=Result/(Foot*Foot);
   end;
end;{FindWaterViscosity}

{---------------------------------------------------------------------------------------------------}
{                                       TFreeUndoObject                                             }
{                                                                                                   }
{   TFreeUndoObject is an object class for undoing actions.                                         }
{   It's function is very basic, just before each modification the file is saved to a the           }
{   undo object rather then to a file. When the undo is called, the previous state will be          }
{   read from the undo object and restored                                                          }
{---------------------------------------------------------------------------------------------------}
// calculates the amount of bytes used for each undo object
function TFreeUndoObject.FGetMemory:integer;
begin
   Result:=4+                       // pointer to self
           4+                       // pointer to owner
           length(Undotext)+        // length of string
           length(FFilename)+       // length of filename string
           FUndoData.Count;         // Actual saved data
end;{TFreeUndoObject.FGetMemory}

function TFreeUndoObject.FGetTime:string;
begin
   Result:=TimeToStr(FTime);
end;{TFreeUndoObject.FGetTime}

function TFreeUndoObject.FGetUndoText:string;
begin
   Result:=FUndoText;
end;{TFreeUndoObject.FGetUndoText}

procedure TFreeUndoObject.Accept;
var I  :Integer;
    Obj:TFreeUndoObject;
begin
   try
      // Add the undo data to the undolist
      if Owner.UndoCount>0 then
      begin
         if Owner.UndoObject[Owner.UndoCount-1].FIsTempRedoObject then
         begin
            Owner.UndoObject[Owner.UndoCount-1].Delete;
         end;
      end;
      // delete all undo objects after the current one
      for I:=FOwner.FUndoObjects.Count downto Owner.FUndoPosition+1 do
      begin
         Owner.UndoObject[I-1].Delete;
      end;
      Owner.FUndoObjects.Add(self);
      Owner.FUndoPosition:=Owner.FUndoObjects.Count;
      while (FOwner.UndoMemory/(1024*1024)>Owner.Preferences.MaxUndoMemory) and (Owner.FUndoObjects.Count>2) do
      begin
         Obj:=FOwner.FUndoObjects[0];
         Obj.Destroy;
         FOwner.FUndoObjects.Delete(0);
         Dec(Owner.FUndoPosition);
         Dec(Owner.FPreviousUndoPosition);
      end;

   finally
      if Assigned(Owner.FOnUpdateUndoData) then Owner.FOnUpdateUndoData(Owner);
   end;

end;{TFreeUndoObject.Accept}

constructor TFreeUndoObject.Create(Owner:TFreeShip);
begin
   inherited Create;
   FTime:=Now;
   FOwner:=Owner;
   FUndoText:='';
   FFilename:='';
   FUndoData:=TFreeFileBuffer.Create;
   FIsTempRedoObject:=False;
end;{TFreeUndoObject.Create}

// deletes an undo object from the list
procedure TFreeUndoObject.Delete;
var Index:integer;
begin
   Index:=FOwner.FUndoObjects.IndexOf(self);
   if Index<>-1 then Owner.FUndoObjects.Delete(Index);
   if Assigned(Owner.FOnUpdateUndoData) then Owner.FOnUpdateUndoData(Owner);
   Destroy;
end;{TFreeUndoObject.Delete}

destructor TFreeUndoObject.Destroy;
begin
   FUndoData.Destroy;
   Inherited Destroy;
end;{TFreeUndoObject.Destroy}

procedure TFreeUndoObject.Restore;
begin
   try
      Owner.LoadBinary(FUndoData);
      Owner.FFileChanged:=FFileChanged;
      Owner.FFilename:=FFilename;
      Owner.FEditMode:=FEditMode;
      Owner.FFilenameSet:=FFilenameSet;
   finally
      Owner.Redraw;
   end;
end;{TFreeUndoObject.Restore}

{---------------------------------------------------------------------------------------------------}
{                                       TFreeBackgroundImageData                                    }
{                                                                                                   }
{   Freeship can import a max. of three different background images that may be coupled either      }
{   to the bodyplan, profile or planview. These images can be used to trace the lines of an         }
{   hullform and are stored within the FREE!ship file.                                              }
{---------------------------------------------------------------------------------------------------}
procedure TFreeBackgroundImageData.Clear;
begin
   FAssignedView:=fvPerspective;
   FImageData.Free;
   FImageData:=TJPEGImage.Create;
   FQuality:=100;
   FOrigin.X:=0;
   FOrigin.Y:=0;
   FScale:=10;
   FBlendingValue:=255;
   FTransparent:=False;
   FTransparentColor:=clBlack;
   FVisible:=True;
   FTolerance:=3;
end;{TFreeBackgroundImageData.Clear}

constructor TFreeBackgroundImageData.Create(Owner:TFreeship);
begin
   Inherited Create;
   FOwner:=Owner;
   FImageData:=TJPEGImage.Create;
end;{TFreeBackgroundImageData.Create}

destructor TFreeBackgroundImageData.Destroy;
begin
   Clear;
   FImageData.Destroy;
   Inherited Destroy;
end;{TFreeBackgroundImageData.Destroy}

procedure TFreeBackgroundImageData.LoadBinary(Source:TFreeFileBuffer);
var I:Integer;
begin
   Source.Load(I);
   FAssignedView:=TFreeViewType(I);
   Source.Load(FVisible);
   Source.Load(FQuality);
   Source.Load(FOrigin.X);
   Source.Load(FOrigin.Y);
   Source.Load(FScale);
   Source.Load(FBlendingValue);
   Source.Load(FTransparent);
   Source.Load(FTransparentColor);
   Source.Load(FTolerance);
   Source.Load(FImageData);
end;{TFreeBackgroundImageData.LoadBinary}

procedure TFreeBackgroundImageData.SaveBinary(Destination:TFreeFileBuffer);
begin
   destination.Add(Ord(AssignedView));
   Destination.Add(FVisible);
   Destination.Add(FQuality);
   Destination.Add(FOrigin.X);
   Destination.Add(FOrigin.Y);
   Destination.Add(FScale);
   Destination.Add(FBlendingValue);
   Destination.Add(FTransparent);
   Destination.Add(FTransparentColor);
   Destination.Add(FTolerance);
   FImageData.CompressionQuality:=FQuality;
   Destination.Add(FImageData);
end;{TFreeBackgroundImageData.SaveBinary}

procedure TFreeBackgroundImageData.UpdateData(Viewport:TFreeViewport);
var I:Integer;
begin
   FOrigin:=Viewport.BackgroundImage.Origin;
   FScale:=Viewport.BackgroundImage.Scale;
   FTransparent:=Viewport.BackgroundImage.Transparent;
   FBlendingValue:=Viewport.BackgroundImage.Alpha;
   FTransparentColor:=Viewport.BackgroundImage.TransparentColor;
   FTolerance:=Viewport.BackgroundImage.Tolerance;
   for I:=1 to FOwner.NumberOfViewports do if (FOwner.Viewport[I-1]<>Viewport) and (FOwner.Viewport[I-1].ViewType=AssignedView) then
   begin
      FOwner.Viewport[I-1].BackgroundImage.AssignData(FImageData,AssignedView,FOrigin,FScale,FTransparent,FTransparentColor,FBlendingValue,FQuality,Ftolerance,False);
   end;
   FOwner.FileChanged:=True;
end;{TFreeBackgroundImageData.UpdateData}

procedure TFreeBackgroundImageData.UpdateViews;
var I:Integer;
begin
   for I:=1 to FOwner.NumberOfViewports do if FOwner.Viewport[I-1].Viewtype=AssignedView then
   begin
      FOwner.Viewport[I-1].BackgroundImage.AssignData(FImageData,AssignedView,FOrigin,FScale,FTransparent,FTransparentColor,FBlendingValue,FQuality,FTolerance,False);
   end;
end;{TFreeBackgroundImageData.UpdateViews}

{---------------------------------------------------------------------------------------------------}
{                                       TFreeHydrostaticCalc                                        }
{                                                                                                   }
{   TFreeHydrostaticCalc is an object class for hydrostatic calculations.                           }
{   Each calculation has it's own draft, trim and angle of heel.                                    }
{   Multiple calculations can be stored and then send to a report.                                  }
{---------------------------------------------------------------------------------------------------}
function TFreeHydrostaticCalc.FGetErrorString:string;
begin
   Result:='';
   if feNothingSubmerged in Errors then Result:=Result+UserString(0)+EOL;
   if feMakingWater in Errors then Result:=Result+UserString(1)+#32+FloatToStrF(FData.Leak.X,ffFixed,7,3)+', '+
                                                                    FloatToStrF(FData.Leak.Y,ffFixed,7,3)+', '+
                                                                    FloatToStrF(FData.Leak.Z,ffFixed,7,3)+EOL;
end;{TFreeHydrostaticCalc.FGetErrorString}

function TFreeHydrostaticCalc.FGetTrimAngle:TFloatType;
begin
   Result:=RadToDeg(ArcTan((-Trim*Cos(DegToRad(HeelingAngle)))/Owner.ProjectSettings.ProjectLength));
end;{TFreeHydrostaticCalc.FGetTrimAngle}

function TFreeHydrostaticCalc.FGetWlPlane:T3DPlane;
var LowestValue:TFloatType;
    P1,P2,P3:T3DCoordinate;
begin
   LowestValue:=Owner.FindLowestHydrostaticsPoint;
   P1:=SetPoint(0.0,0.0,LowestValue+(Draft-0.5*Trim));
   P2:=SetPoint(Owner.ProjectSettings.ProjectLength,0.0,LowestValue+(Draft+0.5*Trim));
   P3:=SetPoint(Owner.ProjectSettings.ProjectLength,Cos(DegToRad(-HeelingAngle)),LowestValue+(Draft+0.5*Trim)-Sin(DegToRad(-HeelingAngle)));
   Result:=PlanePPP(P1,P2,P3);
end;{TFreeHydrostaticCalc.FGetWlPlane}

procedure TFreeHydrostaticCalc.FSetCalculated(val:Boolean);
begin
   FCalculated:=val;
   if not FCalculated then
   begin
      Errors:=[];
      Fillchar(FData,SizeOf(FData),0);
      FMainframe.Clear;
   end;
end;{TFreeHydrostaticCalc.FSetCalculated}

procedure TFreeHydrostaticCalc.FSetHeelingAngle(Val:TFloatType);
begin
   if Val<>FHeelingAngle then
   begin
      FheelingAngle:=val;
      Calculated:=False;
   end;
end;{TFreeHydrostaticCalc.FSetHeelingAngle}

procedure TFreeHydrostaticCalc.FSetTrim(Val:TFloatType);
begin
   if Val<>FTrim then
   begin
      FTrim:=val;
      Calculated:=False;
   end;
end;{TFreeHydrostaticCalc.FSetTrim}

procedure TFreeHydrostaticCalc.FSetDraft(Val:TFloatType);
begin
   if Val<>FDraft then
   begin
      FDraft:=val;
      Calculated:=False;
   end;
end;{TFreeHydrostaticCalc.FSetDraft}

procedure TFreeHydrostaticCalc.FSetErrors(val:TFreeHydrostaticErrors);
begin
   FErrors:=val;
end;{TFreeHydrostaticCalc.FSetErrors}

procedure TFreeHydrostaticCalc.FSetHydrostaticType(val:TFreeHydrostaticType);
begin
   if Val<>FHydrostaticType then
   begin
      FHydrostaticType:=val;
      Calculated:=False;
   end;
end;{TFreeHydrostaticCalc.FSetHydrostaticType}

// Add calculated data to a stringlist to either show in a report or save to disc
procedure TFreeHydrostaticCalc.AddData(Strings:TStringlist;Mode:TFreeHydrostaticsMode;Separator:char);
var Str        : string;
    I,N        : integer;
    Properties : TLayerProperties;
    Total      : TLayerProperties;
    Position   : TFloatType;

begin
   Separator:=#32;
   if not Calculated then Calculate;
   if Errors=[] then
   begin
      if Mode=fhSingleCalculation then
      begin
         AddHeader(Strings);
         Strings.Add(UserString(2)+':');
         Strings.Add(Space(4)+Makelength(Userstring(3),38)+' : '+Separator+MakeLength(FData.Volume,-1,12)+Separator+VolStr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+Makelength(Userstring(4),38)+' : '+Separator+MakeLength(FData.Displacement,-1,12)+Separator+WeightStr(Owner.ProjectSettings.ProjectUnits));
         if Owner.ProjectSettings.ProjectCoefficients=fcActualData then
         begin
            Strings.Add(Space(4)+MakeLength(Userstring(5),38)+' : '+Separator+MakeLength(FData.SubMax.X-FData.SubMin.X,3,12)+Separator+LengthStr(Owner.ProjectSettings.ProjectUnits));
            Strings.Add(Space(4)+MakeLength(Userstring(6),38)+' : '+Separator+MakeLength(FData.SubMax.Y-FData.SubMin.Y,3,12)+Separator+LengthStr(Owner.ProjectSettings.ProjectUnits));
         end;
         Strings.Add(Space(4)+MakeLength(Userstring(7),38)+' : '+Separator+MakeLength(FData.BlockCoefficient,4,12));
         Strings.Add(Space(4)+MakeLength(Userstring(8),38)+' : '+Separator+MakeLength(FData.PrismCoefficient,4,12));
         Strings.Add(Space(4)+MakeLength(Userstring(9),38)+' : '+Separator+MakeLength(FData.VertPrismCoefficient,4,12));
         Strings.Add(Space(4)+MakeLength(Userstring(10),38)+' : '+Separator+MakeLength(FData.WettedSurface,-1,12)+Separator+Areastr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+MakeLength(Userstring(11),38)+' : '+Separator+MakeLength(FData.CenterOfBuoyancy.X,-1,12)+Separator+LengthStr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+MakeLength(Userstring(11),38)+' : '+Separator+MakeLength(FData.LCBPerc,3,12)+Separator+'[%]');
         Strings.Add(Space(4)+MakeLength(Userstring(12),38)+' : '+Separator+MakeLength(FData.CenterOfBuoyancy.Z,-1,12)+Separator+LengthStr(Owner.ProjectSettings.ProjectUnits));

         Strings.Add(Userstring(13)+':');
         Strings.Add(Space(4)+MakeLength(Userstring(14),38)+' : '+Separator+MakeLength(FData.MainframeArea,-1,12)+Separator+Areastr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+MakeLength(Userstring(15),38)+' : '+Separator+MakeLength(FData.MainframeCoeff,4,12));
         Strings.Add(Userstring(16)+':');
         Strings.Add(Space(4)+MakeLength(Userstring(17),38)+' : '+Separator+MakeLength(FData.LengthWaterline,-1,12)+Separator+LengthStr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+MakeLength(Userstring(18),38)+' : '+Separator+MakeLength(FData.BeamWaterline,-1,12)+Separator+LengthStr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+MakeLength(Userstring(19),38)+' : '+Separator+MakeLength(FData.WaterplaneArea,-1,12)+Separator+Areastr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+MakeLength(Userstring(20),38)+' : '+Separator+MakeLength(FData.WaterplaneCoeff,4,12));
         Strings.Add(Space(4)+MakeLength(Userstring(21),38)+' : '+Separator+MakeLength(FData.WaterplaneCOG.X,-1,12)+Separator+LengthStr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+MakeLength(Userstring(22),38)+' : '+Separator+MakeLength(FData.WaterplaneEntranceAngle,-1,12)+Separator+'[degr.]');
         Strings.Add(Space(4)+MakeLength(Userstring(23),38)+' : '+Separator+MakeLength(FData.WaterplaneMomInertia.X,-1,12)+Separator+InertiaStr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+MakeLength(Userstring(24),38)+' : '+Separator+MakeLength(FData.WaterplaneMomInertia.Y,-1,12)+Separator+InertiaStr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Userstring(25)+':');
         Strings.Add(Space(4)+MakeLength(Userstring(26),38)+' : '+Separator+MakeLength(FData.KMtransverse,-1,12)+Separator+LengthStr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+MakeLength(Userstring(27),38)+' : '+Separator+MakeLength(FData.KMlongitudinal,-1,12)+Separator+LengthStr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Userstring(28)+':');
         Strings.Add(Space(4)+MakeLength(Userstring(29),38)+' : '+Separator+MakeLength(FData.LateralArea,-1,12)+Separator+Areastr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+MakeLength(Userstring(30),38)+' : '+Separator+MakeLength(FData.LateralCOG.X,-1,12)+Separator+LengthStr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+MakeLength(Userstring(31),38)+' : '+Separator+MakeLength(FData.LateralCOG.Z,-1,12)+Separator+LengthStr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add('');
         Strings.Add('');
      end else
      begin
         if Strings.Count=0 then
         begin
            AddHeader(Strings);
            Strings.Add(' |  Draft |   Trim  |   Lwl   |   Bwl  |   Vol   |  Displ  |   LCB   |   VCB  |   CB   |   AM   |   CM   |   AW   |   CW   |   CP   |    S   |  KMtrv | KMlong | ');
            if Owner.ProjectSettings.ProjectUnits=fuImperial then
            Strings.Add(' |  [ft]  |   [ft]  |   [ft]  |  [ft]  |  [ft3]  |   [t]   |   [ft]  |  [ft]  |        |  [ft2] |        |  [ft2] |        |        |  [ft2] |  [ft]  |  [ft]  | ')
       else Strings.Add(' |  [m]   |   [m]   |   [m]   |   [m]  |   [m3]  |   [t]   |   [m]   |   [m]  |        |  [m2]  |        |  [m2]  |        |        |  [m2]  |   [m]  |   [m]  | ');
            Strings.Add(' |--------+---------+---------+--------+---------+---------+---------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------| ');
         end;
         Strings.Add(' | '+Makelength(Draft,3,6)+' | '+
                     Makelength(Trim,3,7)+' | '+
                     Makelength(FData.LengthWaterline,-1,7)+' | '+
                     Makelength(FData.BeamWaterline,-1,6)+' | '+
                     MakeLength(FData.Volume,-1,7)+' | '+
                     MakeLength(FData.Displacement,-1,7)+' | '+
                     MakeLength(FData.CenterOfBuoyancy.X,-1,7)+' | '+
                     MakeLength(FData.CenterOfBuoyancy.Z,-1,6)+' | '+
                     MakeLength(FData.BlockCoefficient,4,6)+' | '+
                     MakeLength(FData.MainframeArea,-1,6)+' | '+
                     MakeLength(FData.MainframeCoeff,4,6)+' | '+
                     MakeLength(FData.WaterplaneArea,-1,6)+' | '+
                     MakeLength(FData.WaterplaneCoeff,4,6)+' | '+
                     MakeLength(FData.PrismCoefficient,4,6)+' | '+
                     MakeLength(FData.WettedSurface,-1,6)+' | '+
                     MakeLength(FData.KMtransverse,-1,6)+' | '+
                     MakeLength(FData.KMlongitudinal,-1,6)+' | ');
      end;
   end else Strings.Add(ErrorString);

   if Mode=fhSingleCalculation then
   begin
      // Check if any layers are present to show
      N:=0;
      for I:=1 to Owner.NumberOfLayers do if Owner.Layer[I-1].Count>0 then inc(N);
      if N>0 then
      begin
         for i:=1 to 2 do Strings.Add('');
         Fillchar(Total,SizeOf(Total),0);
         Strings.Add(Userstring(32)+':');
         Strings.Add('|'+space(10)+Makelength(UserString(33),14)+' | '+
                                   Makelength(UserString(34),6)+' | '+
                                   Makelength(UserString(35),9)+' | '+
                                   Makelength(UserString(36),8)+' | '+
                                   ' COG X  |  COG Y  |  COG Z  |');
         Strings.Add('| '+MakeLength('',23)+
                    ' | '+Makelength(AreaStr(Owner.ProjectSettings.ProjectUnits),6)+
                    ' | '+Makelength('',9)+
                    ' | '+Makelength(WeightStr(Owner.ProjectSettings.ProjectUnits),8)+
                    ' | '+MakeLength(LengthStr(Owner.ProjectSettings.ProjectUnits),7)+
                    ' | '+MakeLength(LengthStr(Owner.ProjectSettings.ProjectUnits),7)+
                    ' | '+MakeLength(LengthStr(Owner.ProjectSettings.ProjectUnits),7)+' |');

         Strings.Add('|-------------------------|--------|-----------|----------|---------|---------|---------|');

         for I:=1 to Owner.NumberOfLayers do if Owner.Layer[I-1].Count>0 then
         begin
            Properties:=Owner.Layer[I-1].SurfaceProperties;
            Properties.SurfaceCenterOfGravity.Z:=Properties.SurfaceCenterOfGravity.Z-FData.ModelMin.Z;
            if Owner.ProjectSettings.ProjectUnits=fuImperial then Properties.Weight:=Properties.Weight/(12*2240)
                                                             else Properties.Weight:=Properties.Weight/1000;

            Str:=Owner.Layer[I-1].Name;
            While Length(Str)<23 do Str:=Str+#32;
            if length(Str)>23 then Str:=Copy(Str,1,23);
            Strings.Add('| '+Str+' | '+Makelength(Properties.SurfaceArea,-1,6)+
                                 ' | '+MakeLength(Owner.Layer[I-1].Thickness,3,9)+
                                 ' | '+Makelength(Properties.Weight,3,8)+
                                 ' | '+MakeLength(Properties.SurfaceCenterOfGravity.X,3,7)+
                                 ' | '+MakeLength(Properties.SurfaceCenterOfGravity.Y,3,7)+
                                 ' | '+MakeLength(Properties.SurfaceCenterOfGravity.Z,3,7)+' |');
            Total.SurfaceArea:=Total.SurfaceArea+Properties.SurfaceArea;
            Total.Weight:=Total.Weight+Properties.Weight;
            Total.SurfaceCenterOfGravity.X:=Total.SurfaceCenterOfGravity.X+Properties.Weight*Properties.SurfaceCenterOfGravity.X;
            Total.SurfaceCenterOfGravity.Y:=Total.SurfaceCenterOfGravity.Y+Properties.Weight*Properties.SurfaceCenterOfGravity.Y;
            Total.SurfaceCenterOfGravity.Z:=Total.SurfaceCenterOfGravity.Z+Properties.Weight*Properties.SurfaceCenterOfGravity.Z;
         end;
         if N>1 then
         begin
            // if more then 1 layer is added, then show the properties of all layers together
            Strings.Add('|-------------------------|--------|-----------|----------|---------|---------|---------|');
            if Total.Weight<>0 then
            begin
               Total.SurfaceCenterOfGravity.X:=Total.SurfaceCenterOfGravity.X/Total.Weight;
               Total.SurfaceCenterOfGravity.Y:=Total.SurfaceCenterOfGravity.Y/Total.Weight;
               Total.SurfaceCenterOfGravity.Z:=Total.SurfaceCenterOfGravity.Z/Total.Weight;
            end;
            Str:=UserString(37);
            While Length(Str)<23 do Str:=Str+#32;
            Strings.Add('  '+Str+'   '+Makelength(Total.SurfaceArea,-1,6)+
                                 '   '+MakeLength('',9)+
                                 '   '+Makelength(Total.Weight,3,8)+
                                 '   '+MakeLength(Total.SurfaceCenterOfGravity.X,3,7)+
                                 '   '+MakeLength(Total.SurfaceCenterOfGravity.Y,3,7)+
                                 '   '+MakeLength(Total.SurfaceCenterOfGravity.Z,3,7));
         end;
         // Add sectional Area data
         N:=Length(FData.SAC);
         if N>0 then
         begin
            begin
               Strings.Add('');
               Strings.Add('');
               Strings.Add(UserString(38)+':');
               Strings.Add('');

               Strings.Add(' | '+MakeLength(Userstring(57),9)+' | '+
                                 MakeLength(Userstring(34),8)+' |');
               if Owner.ProjectSettings.ProjectUnits=fuImperial then Strings.Add(' |    [ft]   |   [ft2]  |')
                                                                else Strings.Add(' |    [m]    |    [m2]  |');
               Strings.Add(' |-----------+----------|');
               for I:=1 to N do
               begin
                  Position:=FData.Sac[I-1].X;
                  Strings.Add(' | '+Makelength(Position,3,9)+' | '+
                                    Makelength(Fdata.Sac[I-1].Y,3,8)+' | ');
               end;
               Strings.Add(' |-----------+----------|');
            end;
         end;

      end;
      AddFooter(Strings,Mode);
   end;
end;{TFreeHydrostaticCalc.AddData}

procedure TFreeHydrostaticCalc.AddHeader(Strings:TStringlist);
begin
   Strings.Add(MakeLength(Userstring(39),21)+' : '+Owner.ProjectSettings.ProjectName);
   Strings.Add(MakeLength(Userstring(40),21)+' : '+Owner.ProjectSettings.ProjectDesigner);
   if Owner.ProjectSettings.ProjectFileCreatedBy<>'' then Strings.Add(MakeLength(Userstring(41),21)+' : '+Owner.ProjectSettings.ProjectFileCreatedBy);
   if Owner.ProjectSettings.ProjectComment<>'' then Strings.Add(MakeLength(Userstring(42),21)+' : '+Owner.ProjectSettings.ProjectComment);
   Strings.Add(MakeLength(Userstring(43),21)+' : '+Owner.Filename);
   Strings.Add('');
   Strings.Add(MakeLength(Userstring(44),21)+' : '+MakeLength(Owner.ProjectSettings.ProjectLength,-1,10)+#32+LengthStr(Owner.ProjectSettings.ProjectUnits));
   Strings.Add(MakeLength(Userstring(45),21)+' : '+MakeLength(FData.ModelMax.X-FData.ModelMin.X,-1,10)+#32+LengthStr(Owner.ProjectSettings.ProjectUnits));
   Strings.Add(MakeLength(Userstring(46),21)+' : '+MakeLength(Owner.ProjectSettings.ProjectBeam,-1,10)+#32+LengthStr(Owner.ProjectSettings.ProjectUnits));
   Strings.Add(MakeLength(Userstring(47),21)+' : '+MakeLength(2*FData.ModelMax.Y,-1,10)+#32+LengthStr(Owner.ProjectSettings.ProjectUnits));
   Strings.Add(MakeLength(Userstring(48),21)+' : '+MakeLength(Owner.ProjectSettings.Projectdraft,-1,10)+#32+LengthStr(Owner.ProjectSettings.ProjectUnits));
   Strings.Add(MakeLength(Userstring(49),21)+' : '+MakeLength(Owner.ProjectSettings.ProjectMainframeLocation,-1,10)+#32+LengthStr(Owner.ProjectSettings.ProjectUnits));
   Strings.Add(MakeLength(Userstring(50),21)+' : '+MakeLength(Owner.ProjectSettings.ProjectWaterDensity,3,10)+#32+DensityStr(Owner.ProjectSettings.ProjectUnits));
   Strings.Add(MakeLength(Userstring(51),21)+' : '+MakeLength(Owner.ProjectSettings.ProjectAppendageCoefficient,4,10));
end;{TFreeHydrostaticCalc.AddHeader}

Procedure TFreeHydrostaticCalc.AddFooter(Strings:TStringlist;Mode:TFreeHydrostaticsMode);
begin
   Strings.Add(Userstring(52)+' (Z= '+FloatToStrF(FData.ModelMin.Z,ffFixed,7,3)+')');
   if FOwner.ProjectSettings.ProjectCoefficients=fcActualData then Strings.Add(Userstring(53))
                                                             else Strings.Add(Userstring(54));
   Strings.Add('');
   if Mode=fhMultipleCalculations then
   begin
      Strings.Add('Lwl    : '+Userstring(17));
      Strings.Add('Bwl    : '+Userstring(18));
      Strings.Add('Volume : '+Userstring(3));
      Strings.Add('Displ. : '+Userstring(4));
      Strings.Add('LCB    : '+Userstring(11)+', '+UserString(55));
      Strings.Add('VCB    : '+Userstring(12)+', '+UserString(56));
      Strings.Add('Cb     : '+Userstring(7));
      Strings.Add('Am     : '+Userstring(14));
      Strings.Add('Cm     : '+Userstring(15));
      Strings.Add('Aw     : '+Userstring(19));
      Strings.Add('Cw     : '+Userstring(20));
      Strings.Add('LCF    : '+Userstring(21));
      Strings.Add('CP     : '+Userstring(8));
      Strings.Add('S      : '+Userstring(10));
      Strings.Add('KMt    : '+Userstring(26));
      Strings.Add('KMl    : '+Userstring(27));
   end;
end;{TFreeHydrostaticCalc.AddFooter}

function TFreeHydrostaticCalc.Balance(Displacement:TFloatType;FreeToTrim:Boolean;var Output:TFreeCrosscurvesData):boolean;

const MaxIterations  = 25;
      MaxError       = 5e-4;
      MaxTrimError   = 1e-4;

Type TTrimData  = record
                     Trim  : single;
                     LCB   : single;
                  end;
     TDraftdata = record
                     Draft  : single;
                     Displ  : single;
                  end;
     TMinMaxdata= record
                     LowestPoint : T3DCoordinate;
                     Lowestleak  : T3DCoordinate;
                     PlaneNormal : T3DCoordinate;
                     Maxdraft    : TFloatType;
                     LowestZ     : TFloatType;
                     Calculated  : Boolean;
                  end;


var TrimIteration    : Integer;
    DisplIteration   : Integer;
    FCosHeel         : TFloatType;
    FSinHeel         : TFloatType;
    FCosTrim         : TFloatType;
    FSinTrim         : TFloatType;
    Error,TrimError  : TFloatType;
    ErrorDifference  : TFloatType;
    PrevError        : TFloatType;
    WlPlane          : T3DPlane;
    MinDraft         : TDraftData;
    Maxdraft         : TDraftData;
    CurrDraft        : TDraftData;
    MinMaxData       : TMinMaxdata;

   function Interpolate(X,x1,y1,x2,y2:Single):Single;
   begin
      if abs(X2-X1)<1e-3 then Result:=0.5*(Y1+Y2)
                         else Result:=Y1+(Y2-Y1)*(X-X1)/(X2-X1);
      if (Result<Y1) or (result>Y2) then Result:=0.5*(Y1+Y2);
   end;{Interpolate}

   function RotatePointBack(P:T3DCoordinate):T3DCoordinate;
   // Rotate a point under given trim and heel back to heel=0 and trim=0 position
   begin
      Result.x:= P.x*FCosTrim-P.z*FSinTrim;
      Result.y:= P.y*FCosHeel+P.x*FSinTrim*FSinHeel+P.z*FCosTrim*FSinHeel;
      Result.z:=-P.y*FSinHeel+P.x*FSinTrim*FCosHeel+P.z*FCosTrim*FCosHeel;
   end;{RotatePointBack}

   function CalculatewaterlinePlane(Desireddraft:TFloatType):T3DPlane;
   var P:T3DCoordinate;
   begin
      P.X:=MinMaxdata.LowestPoint.X+Desireddraft*MinMaxdata.PlaneNormal.X;
      P.Y:=MinMaxdata.LowestPoint.Y+Desireddraft*MinMaxdata.PlaneNormal.Y;
      P.Z:=MinMaxdata.LowestPoint.Z+Desireddraft*MinMaxdata.PlaneNormal.Z;
      Result:=PlanePointNormal(P,MinMaxdata.PlaneNormal);
   end;{CalculatewaterlinePlane}

   procedure CalculateMinMaxdata;
   var I,J,K,L    : Integer;
       P1,P2,P3   : T3DCoordinate;
       First      : Boolean;
       FirstLeak  : Boolean;
       Min,Max    : TFloatType;
       Distance   : TFloatType;
       Tmp        : TFloatType;
       Layer      : TFreeSubdivisionLayer;
       Face       : TFreeSubdivisionControlface;
       Child      : TFreeSubdivisionFace;
   begin
      Fillchar(MinMaxdata,SizeOf(TMinMaxdata),0);
      P1:=RotatePointBack(SetPoint(0.0,0.0,0.0));
      P2:=RotatePointBack(SetPoint(1.0,0.0,0.0));
      P3:=RotatePointBack(SetPoint(1.0,1.0,0.0));
      // The following plane has the right orientation for the given trim and angle of heel,
      // however the correct distance from the lowest point on the hull has to be calculated
      MinMaxdata.PlaneNormal:=UnifiedNormal(P1,P2,P3);
      WlPlane:=PlanePPP(P1,P2,P3);

      // Calculate min/max possible draft under this condition
      First:=True;
      Firstleak:=True;
      Min:=0;
      Max:=0;
      for I:=1 to owner.NumberOfLayers do if Owner.Layer[I-1].UseInHydrostatics then
      begin
         Layer:=owner.Layer[I-1];
         for J:=1 to Layer.Count do
         begin
            Face:=Layer.Items[J-1];
            for K:=1 to Face.ChildCount do
            begin
               Child:=Face.Child[K-1];
               for L:=1 to Child.NumberOfpoints do
               begin
                  P1:=Child.Point[L-1].Coordinate;
                  Distance:=WlPlane.A*P1.x+WlPlane.B*P1.y+WlPlane.C*P1.z+WlPlane.D;
                  if First then
                  begin
                     Min:=Distance;
                     Max:=min;
                     First:=False;
                     MinMaxdata.LowestPoint:=P1;
                     MinMaxData.LowestZ:=P1.Z;
                  end else
                  begin
                     if Distance<Min then
                     begin
                        Min:=Distance;
                        MinMaxdata.LowestPoint:=P1;
                     end else if Distance>Max then Max:=Distance;
                     if P1.Z<MinMaxData.LowestZ then MinMaxData.LowestZ:=P1.Z;
                  end;
                  P1.Y:=-P1.Y;
                  Distance:=WlPlane.A*P1.x+WlPlane.B*P1.y+WlPlane.C*P1.z+WlPlane.D;
                  if Distance<Min then
                  begin
                     Min:=Distance;
                     MinMaxdata.LowestPoint:=P1;
                  end else if Distance>MAx then Max:=Distance;

                  // check if this point is a leak point
                  if (abs(Child.Point[L-1].Coordinate.Y)>1e-4) and (Child.Point[L-1].IsBoundaryVertex) then
                  begin
                     P1:=Child.Point[L-1].Coordinate;
                     if Firstleak then
                     begin
                        FirstLeak:=false;
                        MinMaxData.Lowestleak:=P1;
                     end else
                     begin
                        Distance:=WlPlane.A*P1.x+WlPlane.B*P1.y+WlPlane.C*P1.z+WlPlane.D;
                        Tmp:=WlPlane.A*MinMaxData.Lowestleak.x+WlPlane.B*MinMaxData.Lowestleak.y+WlPlane.C*MinMaxData.Lowestleak.z+WlPlane.D;
                        if Distance<Tmp then MinMaxData.Lowestleak:=P1;
                     end;
                     P1.Y:=-P1.Y;
                     Distance:=WlPlane.A*P1.x+WlPlane.B*P1.y+WlPlane.C*P1.z+WlPlane.D;
                     Tmp:=WlPlane.A*MinMaxData.Lowestleak.x+WlPlane.B*MinMaxData.Lowestleak.y+WlPlane.C*MinMaxData.Lowestleak.z+WlPlane.D;
                     if Distance<Tmp then MinMaxData.Lowestleak:=P1;
                  end;
               end;
            end;
         end;
      end;
      if not Firstleak then
      begin
         // leak points have been found, check if this restricts the max draft
         Distance:=WlPlane.A*MinMaxData.Lowestleak.x+WlPlane.B*MinMaxData.Lowestleak.y+WlPlane.C*MinMaxData.Lowestleak.z+WlPlane.D;
         if Distance<Max then max:=Distance;
      end;
      MinMaxdata.Maxdraft:=Max-Min-1e-4;
   end;{Initalizes data of the hull under a specified heel and trim}


begin
   Fillchar(FData,SizeOf(FData),0);
   MinMaxdata.Calculated:=False;
   Fillchar(Output,Sizeof(OutPut),0);

   if Displacement<>0 then
   begin
      Error:=0;
      TrimIteration:=0;
      TrimError:=0.0;
      repeat
         inc(TrimIteration);

         FCosHeel:=Cos(DegTorad(-FHeelingAngle));
         FSinHeel:=Sin(DegTorad(-FHeelingAngle));
         FCosTrim:=Cos(DegToRad(TrimAngle));
         FSinTrim:=Sin(DegToRad(TrimAngle));

         if not MinMaxData.Calculated then CalculateMinMaxData;

         MinDraft.Draft:=0;
         MinDraft.Displ:=0.0;
         MaxDraft.Draft:=MinMaxdata.Maxdraft;
         WlPLane:=CalculatewaterlinePlane(MaxDraft.Draft);
         CalculateVolume(WlPlane);
         MaxDraft.Displ:=self.FData.Displacement;

         if Displacement>1.005*MaxDraft.Displ then
         begin
            Errors:=FErrors+[feNotEnoughBuoyancy];
         end else
         begin

            DisplIteration:=0;
            //if CompCG then CG:=RotatePoint(OrgCOG)
            //          else CG:=OrgCOG;

            PrevError:=0;
            repeat
               inc(DisplIteration);
               CurrDraft.Draft:=Interpolate(Displacement,MinDraft.Displ,MinDraft.Draft,MaxDraft.Displ,MaxDraft.Draft);
               WlPlane:=CalculatewaterlinePlane(CurrDraft.Draft);
               Calculatevolume(WlPlane);
               CurrDraft.Displ:=FData.Displacement;
               if Displacement<0.1 then Error:=abs(Displacement-CurrDraft.Displ)
                                   else Error:=abs((Displacement-CurrDraft.Displ)/Displacement);
               if Error>MaxError then
               begin
                  if CurrDraft.Displ<Displacement then MinDraft:=CurrDraft
                                                  else MaxDraft:=CurrDraft;
               end;
               ErrorDifference:=abs(Error-PrevError);
               PrevError:=Error;
            until ((Error<MaxError) ) or (DisplIteration>MaxIterations) or (ErrorDifference<1e-5);
         end;

         if FreeToTrim then
         begin
            // still to be implemented
         end else TrimError:=0.0;
      until (TrimIteration>MaxIterations) or (TrimError<=MaxTrimError);
      Result:=(TrimError<=MaxTrimError) and (Error<=MaxError) and (Errors=[]);
      if Result then
      begin
         Output.WaterlinePlane:=Fdata.WaterlinePlane;
         Output.AbsoluteDraft:=FData.AbsoluteDraft;
         Output.Volume:=FData.Volume;
         Output.Displacement:=FData.Displacement;
         Output.CenterOfBuoyancy:=FData.CenterOfBuoyancy;
         if abs(HeelingAngle)<1e-5 then Output.CenterOfBuoyancy.Y:=0.0;
      end;
   end else result:=True;
end;{TFreeHydrostaticCalc.Balance}

// The actual calculation of the hydrostatics finds place in this procedure
procedure TFreeHydrostaticCalc.Calculate;
var I,J,K,L          : integer;
    First,Last       : Integer;
    CosHeel          : TFloatType;
    SinHeel          : TFloatType;
    CosTrim          : TFloatType;
    SinTrim          : TFloattype;
    Parameter        : TFloatType;
    Layer            : TFREESubdivisionLayer;
    Face             : TFreeSubdivisionControlFace;
    Child            : TFreeSubdivisionFace;
    Side1,Side2      : TFloatType;
    SubmergedLength  : TFloatType;
    SubmergedWidth   : TFloatType;
    P1,P2            : T3DCoordinate;
    P,Keel           : T3DCoordinate;
    NewOrigin        : T3DCoordinate;
    TmpP2D           : T2DCoordinate;
    FirstSubmPoint   : Boolean;
    FirstPoint       : Boolean;
    Submerged        : Boolean;
    Points           : array of T3DCoordinate;  // Array containing the coordinates of the underwaterpart of a face
    PointCapacity    : integer;                 // Length of the dynamic point-array
    NoPoints         : integer;                 // number of points stored int the dynamic array
    Waterplane       : TFreeIntersection;
    LateralPlane     : TFreeIntersection;
    Frame            : TFreeIntersection;
    Spline           : TFreeSpline;

    function RotatePoint(P:T3DCoordinate):T3DCoordinate;
    // Rotate a point at heel=0 and trim=0 position to given trim and heel
    begin
      P.Z:=P.Z-Keel.Z;
      Result.x:=P.x*CosTrim+P.y*SinHeel*SinTrim+P.z*CosHeel*SinTrim;
      Result.y:=P.y*CosHeel-P.z*SinHeel;
      Result.z:=-P.x*SinTrim+P.y*SinHeel*CosTrim+P.z*CosHeel*CosTrim;
    end;{THydrostaticsData.RotatePoint}

    procedure ProcessTriangle(P1,P2,P3:T3DCoordinate);
    var VolumeMoment : T3DCoordinate;
        Volume       : TFloatType;
        Center       : T3DCoordinate;
        ax,ay,az     : TFloatType;
    begin
       // Reposition points with respect to the new projected origin
       P1.X:=P1.X-NewOrigin.X;
       P1.Y:=P1.Y-NewOrigin.Y;
       P1.Z:=P1.Z-NewOrigin.Z;
       P2.X:=P2.X-NewOrigin.X;
       P2.Y:=P2.Y-NewOrigin.Y;
       P2.Z:=P2.Z-NewOrigin.Z;
       P3.X:=P3.X-NewOrigin.X;
       P3.Y:=P3.Y-NewOrigin.Y;
       P3.Z:=P3.Z-NewOrigin.Z;
       Center.X:=(P1.X+P2.X+P3.X)/3;
       Center.Y:=(P1.Y+P2.Y+P3.Y)/3;
       Center.Z:=(P1.Z+P2.Z+P3.Z)/3;
       Volume:=((P1.z)*(P2.x*P3.y-P2.y*P3.x)+
                (P1.y)*(P2.z*P3.x-P2.x*P3.z)+
                (P1.x)*(P2.y*P3.z-P2.z*P3.y))/6;
       if Volume<>0 then
       begin
          VolumeMoment.X:=0.75*Center.X*Volume;
          VolumeMoment.Y:=0.75*Center.Y*Volume;
          VolumeMoment.Z:=0.75*Center.Z*Volume;
          FData.Volume:=Fdata.Volume+Volume;
          FData.CenterOfBuoyancy.X:=FData.CenterOfBuoyancy.X+VolumeMoment.X;
          FData.CenterOfBuoyancy.Y:=FData.CenterOfBuoyancy.Y+VolumeMoment.Y;
          FData.CenterOfBuoyancy.Z:=FData.CenterOfBuoyancy.Z+VolumeMoment.Z;
       end;
       ax:=0.5*((P1.y-P2.y)*(P1.z+P2.z)+(P2.y-P3.y)*(P2.z+P3.z)+
                (P3.y-P1.y)*(P3.z+P1.z));
       ay:=0.5*((P1.z-P2.z)*(P1.x+P2.x)+(P2.z-P3.z)*(P2.x+P3.x)+
                (P3.z-P1.z)*(P3.x+P1.x));
       az:=0.5*((P1.x-P2.x)*(P1.y+P2.y)+(P2.x-P3.x)*(P2.y+P3.y)+
                (P3.x-P1.x)*(P3.y+P1.y));
       FData.WettedSurface:=FData.WettedSurface+Sqrt(ax*ax+ay*ay+az*az);
    end;{ProcessTriangle}

    procedure CheckSubmergedBody(P:T3DCoordinate;Side:TFloatType);
    begin
      // Calculate extents of waterplane and submerged body
      P:=RotatePoint(P);
      if FirstSubmPoint then
      begin
         FData.SubMin:=P;
         FData.SubMax:=P;
         FirstSubmPoint:=False;
      end else MinMax(P,FData.SubMin,FData.SubMax);
      if (Side>-1e-5) and (Side<1e-5) then
      begin
         // point is exactly on waterplane
         if FirstPoint then
         begin
            // Calculate waterline properties
            FData.WlMin:=P;
            FData.WlMax:=P;
            FirstPoint:=False;
         end else MinMax(P,FData.WlMin,FData.WlMax);
      end;
    end;{CheckSubmergedBody}

begin
   // Initial setup of data
   {
   Draft:=4.567;
   Trim:=-1.824;
   HeelingAngle:=30;

   Draft:=4.713954;
   Trim:=-2.3698;
   HeelingAngle:=40;
   }
   CosHeel:=Cos(DegToRad(-HeelingAngle));
   SinHeel:=Sin(DegToRad(-HeelingAngle));
   CosTrim:=Cos(DegToRad(-TrimAngle));
   SinTrim:=Sin(DegToRad(-TrimAngle));

   Calculated:=False;   // Resets all data and calculated variables
   // Calculate the definition of the waterlineplane
   Keel:=SetPoint(0.0,0.0,Owner.FindLowestHydrostaticsPoint);
   FData.WaterlinePlane:=WaterlinePlane;

   // In order to calculate the volume enclosed by the underwatership correctly,
   // the origin (0.0, 0.0, 0.0) is projected onto the waterline plane
   NewOrigin:=ProjectPointOnPlane(ZERO,FData.WaterlinePlane);

   // Now calculate the actual volume
   FirstPoint:=True;
   Submerged:=False;
   PointCapacity:=5;
   Setlength(Points,PointCapacity);
   FirstSubmPoint:=True;
   FData.AbsoluteDraft:=1000;

   // calculate overall extents of the hull alone
   for I:=1 to Owner.NumberOfLayers do
   begin
      Layer:=Owner.Layer[I-1];
      if Layer.UseInHydrostatics then for J:=1 to Layer.Count do
      begin
         Face:=Layer.Items[J-1];
         for K:=1 to Face.ChildCount do
         begin
            Child:=Face.Child[K-1];
            for L:=1 to Child.NumberOfPoints do
            begin
               P2:=Child.Point[L-1].Coordinate;
               if FirstPoint then
               begin
                  FData.ModelMin:=P2;
                  FData.ModelMax:=P2;
                  FirstPoint:=False;
               end else MinMax(P2,FData.ModelMin,FData.ModelMax);
            end;
         end;
      end;
   end;

   FirstPoint:=True;
   for I:=1 to Owner.NumberOfLayers do
   begin
      Layer:=Owner.Layer[I-1];
      if Layer.UseInHydrostatics then for J:=1 to Layer.Count do
      begin
         Face:=Layer.Items[J-1];
         for K:=1 to Face.ChildCount do
         begin
            Child:=Face.Child[K-1];
            // Calculate the portside of the model
            NoPoints:=0;
            P1:=Child.Point[Child.NumberOfPoints-1].Coordinate;
            // calculate on which side of the waterplane this point is
            Side1:=FData.Waterlineplane.A*P1.x+FData.Waterlineplane.B*P1.y+FData.Waterlineplane.C*P1.z+FData.Waterlineplane.D;
            for L:=1 to Child.NumberOfPoints do
            begin
               P2:=Child.Point[L-1].Coordinate;
               Side2:=FData.Waterlineplane.A*P2.x+FData.Waterlineplane.B*P2.y+FData.Waterlineplane.C*P2.z+FData.Waterlineplane.D;
               if ((Side1<-1e-5) and (Side2>1e-5)) or ((Side1>1e-5) and (Side2<-1e-5)) then
               begin
                  // The current linesegment between P1-P2 intersects the waterlineplae
                  if Side1=Side2 then Parameter:=0.5*(Side1+Side2)
                                 else Parameter:=-Side1/(Side2-Side1);
                  P.X:=P1.X+Parameter*(P2.X-P1.X);
                  P.Y:=P1.Y+Parameter*(P2.Y-P1.Y);
                  P.Z:=P1.Z+Parameter*(P2.Z-P1.Z);
                  Inc(NoPoints);
                  if NoPoints>PointCapacity then
                  begin
                     inc(PointCapacity);
                     Setlength(Points,PointCapacity);
                  end;
                  Points[NoPoints-1]:=P;
                  CheckSubmergedBody(P,0.0);
               end;
               if Side2<=1e-5 then
               begin
                  if Side2<FData.AbsoluteDraft then FData.AbsoluteDraft:=Side2;
                  // P2 lies also on or under the waterlineplane
                  Inc(NoPoints);
                  if NoPoints>PointCapacity then
                  begin
                     inc(PointCapacity);
                     Setlength(Points,PointCapacity);
                  end;
                  Points[NoPoints-1]:=P2;
                  if Side2<-1e-5 then
                  begin
                     // point is submerged, check if the model is making water
                     if (Child.Point[L-1].IsBoundaryVertex) and (abs(Child.Point[L-1].Coordinate.Y)>1e-4) then
                     begin
                        if not (feMakingWater in Errors) then
                        begin
                           Errors:=Errors+[feMakingwater];
                           FData.Leak:=Child.Point[L-1].Coordinate;
                        end;
                     end;
                  end;
                  CheckSubmergedBody(P2,Side2);
               end;
               P1:=P2;
               Side1:=Side2;
            end;

            // calculate volume aft of this face
            if NoPoints>2 then Submerged:=True;
            for L:=3 to NoPoints do ProcessTriangle(Points[0],Points[L-2],Points[L-1]);

            if Layer.Symmetric then
            begin
               // Calculate the starboardside of the model
               NoPoints:=0;
               P1:=Child.Point[Child.NumberOfPoints-1].Coordinate;
               P1.Y:=-P1.Y;
               // calculate on which side of the waterplane this point is
               Side1:=FData.Waterlineplane.A*P1.x+FData.Waterlineplane.B*P1.y+FData.Waterlineplane.C*P1.z+FData.Waterlineplane.D;
               for L:=1 to Child.NumberOfPoints do
               begin
                  P2:=Child.Point[L-1].Coordinate;
                  P2.Y:=-P2.Y;
                  Side2:=FData.Waterlineplane.A*P2.x+FData.Waterlineplane.B*P2.y+FData.Waterlineplane.C*P2.z+FData.Waterlineplane.D;
                  if ((Side1<-1e-5) and (Side2>1e-5)) or ((Side1>1e-5) and (Side2<-1e-5)) then
                  begin
                     // The current linesegment between P1-P2 intersects the waterlineplae
                     if Side1=Side2 then Parameter:=0.5*(Side1+Side2)
                                    else Parameter:=-Side1/(Side2-Side1);
                     P.X:=P1.X+Parameter*(P2.X-P1.X);
                     P.Y:=P1.Y+Parameter*(P2.Y-P1.Y);
                     P.Z:=P1.Z+Parameter*(P2.Z-P1.Z);
                     Inc(NoPoints);
                     if NoPoints>PointCapacity then
                     begin
                        inc(PointCapacity);
                        Setlength(Points,PointCapacity);
                     end;
                     Points[NoPoints-1]:=P;
                     CheckSubmergedBody(P,0.0);
                  end;
                  if Side2<=1e-5 then
                  begin
                     // P2 lies also under the waterlineplane
                     if Side2<FData.AbsoluteDraft then FData.AbsoluteDraft:=Side2;
                     Inc(NoPoints);
                     if NoPoints>PointCapacity then
                     begin
                        inc(PointCapacity);
                        Setlength(Points,PointCapacity);
                     end;
                     Points[NoPoints-1]:=P2;
                     if Side2<-1e-5 then
                     begin
                        // point is submerged, check if the model is making water
                        if (Child.Point[L-1].IsBoundaryVertex) and (abs(Child.Point[L-1].Coordinate.Y)>1e-4) then
                        begin
                           if not (feMakingWater in Errors) then
                           begin
                              Errors:=Errors+[feMakingwater];
                              FData.Leak:=Child.Point[L-1].Coordinate;
                           end;
                        end;
                     end;
                     CheckSubmergedBody(P2,Side2);
                  end;
                  P1:=P2;
                  Side1:=Side2;
               end;
               // calculate volume aft of this face
               if NoPoints>2 then Submerged:=True;
               for L:=3 to NoPoints do ProcessTriangle(Points[0],Points[L-1],Points[L-2],);
            end;
         end;
      end;
   end;
   FData.AbsoluteDraft:=-FData.AbsoluteDraft;
   if FirstPoint then
   begin
      // No intersection with the watersurface found, the ship is either
      // not submerged or totally submerged
      if not submerged then
      begin
         Errors:=Errors+[feNothingSubmerged];
         FData.AbsoluteDraft:=0.0;
      end;
   end;
   if feMakingWater in Errors then
   begin
      FData.Volume:=0.0;
      FData.CenterOfBuoyancy:=ZERO;
   end;

   SubmergedLength:=Fdata.SubMax.X-FData.SubMin.X;
   SubmergedWidth:=FData.SubMax.Y-FData.SubMin.Y;
   FData.Displacement:=VolumeToDisplacement(FData.Volume,Owner.ProjectSettings.ProjectWaterDensity,Owner.ProjectSettings.ProjectAppendageCoefficient,Owner.ProjectSettings.ProjectUnits);
   FData.LengthWaterline:=FData.WlMax.X-FData.WlMin.X;
   FData.BeamWaterline:=FData.WlMax.Y-FData.WlMin.Y;
   if FData.Volume<>0 then
   begin
      // Translate center of buoyancy back to the original origin
      FData.CenterOfBuoyancy.X:=NewOrigin.X+FData.CenterOfBuoyancy.X/FData.Volume;
      FData.CenterOfBuoyancy.Y:=NewOrigin.Y+FData.CenterOfBuoyancy.Y/FData.Volume;
      FData.CenterOfBuoyancy.Z:=NewOrigin.Z+FData.CenterOfBuoyancy.Z/FData.Volume;
      FData.CenterOfBuoyancy:=RotatePoint(FData.CenterOfBuoyancy);
      if FData.LengthWaterline<>0 then FData.LCBPerc:=100*((FData.CenterOfBuoyancy.X-Owner.ProjectSettings.ProjectMainframeLocation)/FData.LengthWaterline);
      // Apply appendage coeff.
      FData.Volume:=FData.Volume*Owner.ProjectSettings.ProjectAppendageCoefficient;
   end;

   if (FData.Volume>0) and (Errors=[]) and ((hcMainframe in Calculations) or (hcAll in Calculations)) then
   begin
      // Calculate mainframe properties
      FMainframe.FIntersectionType:=fiStation;
      FMainframe.FUseHydrostaticsSurfacesOnly:=True;
      FMainframe.FPlane.a:=1.0;
      FMainframe.FPlane.b:=0.0;
      FMainframe.FPlane.c:=0.0;
      FMainframe.FPlane.d:=-Owner.ProjectSettings.ProjectMainframeLocation;
      FMainframe.CalculateArea(FData.WaterlinePlane,FData.MainframeArea,FData.MainframeCOG,TmpP2D);
      FData.MainframeCOG.Z:=FData.MainframeCOG.Z-FData.ModelMin.Z;
      if Owner.ProjectSettings.ProjectCoefficients=fcActualData then
      begin
         if SubmergedWidth*Draft<>0.0 then FData.MainframeCoeff:=FData.Mainframearea/(SubmergedWidth*Draft);
      end else if Owner.ProjectSettings.ProjectBeam*Draft<>0.0 then FData.MainframeCoeff:=FData.Mainframearea/(Owner.ProjectSettings.ProjectBeam*Draft);
   end;

   if (FData.Volume>0) and (Errors=[]) and ((hcWaterline in Calculations) or (hcAll in Calculations)) then
   begin
      // Calculate waterplane properties
      Waterplane:=TFreeIntersection.Create(Owner);
      Waterplane.FIntersectionType:=fiWaterline;
      Waterplane.FPlane:=FData.WaterlinePlane;
      Waterplane.FUseHydrostaticsSurfacesOnly:=True;
      Waterplane.Rebuild;
      Parameter:=-1e6;
      FData.WaterplaneEntranceAngle:=0;
      for J:=1 to Waterplane.Count do
      begin
         Spline:=Waterplane.Items[J-1];
         // Rotate all the points back to a horizontal plane
         for K:=1 to Spline.NumberOfPoints do
         begin
            P1:=Spline.Point[K-1];
            P2:=RotatePoint(P1);
            Spline.Point[K-1]:=P2;
         end;

         if Spline.Value(0.0).X>Spline.Value(1.0).X then Spline.InvertDirection;
         P1:=Spline.Value(1.00);
         if P1.X>Parameter then
         begin
            Parameter:=P1.X;
            P2:=Spline.Value(0.99);
            if P1.X-P2.X<>0 then FData.WaterplaneEntranceAngle:=RadToDeg(ArcTan((P2.Y-P1.Y)/(P1.X-P2.X)))
                            else FData.WaterplaneEntranceAngle:=90.0;
            if P2.Y<P1.Y then FData.WaterplaneEntranceAngle:=-FData.WaterplaneEntranceAngle;
         end;
      end;
      Waterplane.CalculateArea(FData.WaterlinePlane,FData.WaterplaneArea,FData.WaterplaneCOG,FData.WaterplaneMomInertia);
      if Owner.ProjectSettings.ProjectCoefficients=fcActualData then
      begin
         if SubmergedWidth*SubmergedLength<>0.0 then FData.WaterplaneCoeff:=FData.Waterplanearea/(SubmergedWidth*SubmergedLength);
      end else if Owner.ProjectSettings.ProjectBeam*Owner.ProjectSettings.ProjectLength<>0.0 then FData.WaterplaneCoeff:=FData.Waterplanearea/(Owner.ProjectSettings.ProjectBeam*Owner.ProjectSettings.ProjectLength);
      Waterplane.Destroy;
      // Stability data
      FData.KMtransverse:=FData.CenterOfBuoyancy.Z+FData.WaterplaneMomInertia.X/FData.Volume;
      FData.KMlongitudinal:=FData.CenterOfBuoyancy.Z+FData.WaterplaneMomInertia.Y/FData.Volume;
   end;
   if Draft<>0 then
   begin
      if FData.Waterplanearea*Draft<>0 then FData.VertPrismCoefficient:=FData.Volume/(FData.Waterplanearea*Draft);
      if Owner.ProjectSettings.ProjectCoefficients=fcActualData then
      begin
         // Block coefficient based on length and beam measured on the waterline
         if SubmergedWidth*SubmergedLength*Draft<>0.0 then FData.BlockCoefficient:=FData.Volume/(SubmergedWidth*SubmergedLength*Draft);
         // Prismatic coefficient based on length and beam measured on the waterline
         if FData.Mainframearea*SubmergedLength<>0.0 then FData.PrismCoefficient:=FData.Volume/(FData.MainframeArea*SubmergedLength);
      end else
      begin
         // Block coefficient based on length and beam from project settings
         if Owner.ProjectSettings.ProjectLength*Owner.ProjectSettings.ProjectBeam*Draft<>0.0 then FData.BlockCoefficient:=FData.Volume/(Owner.ProjectSettings.ProjectLength*Owner.ProjectSettings.ProjectBeam*Draft);
         // Prismatic coefficient based on length from project settings
         if FData.Mainframearea*Owner.ProjectSettings.ProjectLength<>0.0 then FData.PrismCoefficient:=FData.Volume/(FData.Mainframearea*Owner.ProjectSettings.ProjectLength);
      end;
   end;
   if (hcSAC in Calculations) or (hcAll in Calculations) then
   begin
      // Calculate sectional areas
      if Owner.NumberofStations>0 then
      begin
         Setlength(FData.SAC,Owner.NumberofStations);
         for I:=1 to Owner.NumberofStations do
         begin
            FData.SAC[I-1].X:=0.0;
            FData.SAC[I-1].Y:=0.0;
         end;
         for I:=1 to Owner.NumberofStations do
         begin
            Frame:=TFreeIntersection.Create(Owner);
            Frame.FIntersectionType:=Owner.Station[I-1].FIntersectionType;
            Frame.Plane:=Owner.Station[I-1].Plane;
            Frame.FUseHydrostaticsSurfacesOnly:=True;
            Fdata.Sac[I-1].X:=-Frame.Plane.d;
            Frame.CalculateArea(FData.WaterlinePlane,FData.Sac[I-1].Y,P1,TmpP2D);
            Frame.Destroy;
         end;
         First:=Owner.NumberofStations-1;
         Last:=0;
         for I:=1 to Owner.NumberofStations do if FData.SAC[I-1].Y<>0 then
         begin
            if I-1<First then First:=I-1;
            if I-1>last then Last:=I-1;
         end;
         if First>0 then Dec(First);
         if Last<Owner.NumberofStations-1 then inc(Last);
         for I:=First to Last do FData.SAC[I-First]:=FData.SAC[I];
         if Last-First+1>0 then Setlength(FData.SAC,Last-First+1)
                           else Setlength(FData.SAC,0);
      end
   end;
   if (hcLateralArea in Calculations) or (hcAll in Calculations) then
   begin
      // Calculate lateral area end center of gravity
      LateralPlane:=TFreeIntersection.Create(Owner);
      LateralPlane.FIntersectionType:=fiButtock;
      LateralPlane.FUseHydrostaticsSurfacesOnly:=True;
      LateralPlane.FPlane.a:=0.0;
      LateralPlane.FPlane.b:=1.0;
      LateralPlane.FPlane.c:=0.0;
      LateralPlane.FPlane.d:=-0.001;
      LateralPlane.CalculateArea(FData.WaterlinePlane,FData.LateralArea,FData.LateralCOG,TmpP2D);
      FData.LateralCOG.Z:=FData.LateralCOG.Z-FData.ModelMin.Z;
      LateralPlane.Destroy;
   end;

   Calculated:=True;
end;{TFreeHydrostaticCalc.Calculate}

procedure TFreeHydrostaticCalc.CalculateVolume(WaterlinePlane:T3DPlane);
var I,J,K,L          : integer;
    CosHeel          : TFloatType;
    SinHeel          : TFloatType;
    CosTrim          : TFloatType;
    SinTrim          : TFloattype;
    Parameter        : TFloatType;
    Layer            : TFREESubdivisionLayer;
    Face             : TFreeSubdivisionControlFace;
    Child            : TFreeSubdivisionFace;
    Side1,Side2      : TFloatType;
    P1,P2            : T3DCoordinate;
    P,Keel           : T3DCoordinate;
    NewOrigin        : T3DCoordinate;
    FirstPoint       : Boolean;
    Submerged        : Boolean;
    Points           : array of T3DCoordinate;  // Array containing the coordinates of the underwaterpart of a face
    PointCapacity    : integer;                 // Length of the dynamic point-array
    NoPoints         : integer;                 // number of points stored int the dynamic array

    function RotatePoint(P:T3DCoordinate):T3DCoordinate;
    // Rotate a point at heel=0 and trim=0 position to given trim and heel
    begin
      P.Z:=P.Z-Keel.Z;
      Result.x:=P.x*CosTrim+P.y*SinHeel*SinTrim+P.z*CosHeel*SinTrim;
      Result.y:=P.y*CosHeel-P.z*SinHeel;
      Result.z:=-P.x*SinTrim+P.y*SinHeel*CosTrim+P.z*CosHeel*CosTrim;
    end;{THydrostaticsData.RotatePoint}

    procedure ProcessTriangle(P1,P2,P3:T3DCoordinate);
    var VolumeMoment : T3DCoordinate;
        Volume       : TFloatType;
        Center       : T3DCoordinate;
    begin
       // Reposition points with respect to the new projected origin
       P1.X:=P1.X-NewOrigin.X;
       P1.Y:=P1.Y-NewOrigin.Y;
       P1.Z:=P1.Z-NewOrigin.Z;
       P2.X:=P2.X-NewOrigin.X;
       P2.Y:=P2.Y-NewOrigin.Y;
       P2.Z:=P2.Z-NewOrigin.Z;
       P3.X:=P3.X-NewOrigin.X;
       P3.Y:=P3.Y-NewOrigin.Y;
       P3.Z:=P3.Z-NewOrigin.Z;
       Center.X:=(P1.X+P2.X+P3.X)/3;
       Center.Y:=(P1.Y+P2.Y+P3.Y)/3;
       Center.Z:=(P1.Z+P2.Z+P3.Z)/3;
       Volume:=((P1.z)*(P2.x*P3.y-P2.y*P3.x)+
                (P1.y)*(P2.z*P3.x-P2.x*P3.z)+
                (P1.x)*(P2.y*P3.z-P2.z*P3.y))/6;
       if Volume<>0 then
       begin
          VolumeMoment.X:=0.75*Center.X*Volume;
          VolumeMoment.Y:=0.75*Center.Y*Volume;
          VolumeMoment.Z:=0.75*Center.Z*Volume;
          FData.Volume:=Fdata.Volume+Volume;
          FData.CenterOfBuoyancy.X:=FData.CenterOfBuoyancy.X+VolumeMoment.X;
          FData.CenterOfBuoyancy.Y:=FData.CenterOfBuoyancy.Y+VolumeMoment.Y;
          FData.CenterOfBuoyancy.Z:=FData.CenterOfBuoyancy.Z+VolumeMoment.Z;
       end;
    end;{ProcessTriangle}

begin
   // Initial setup of data
   CosHeel:=Cos(DegToRad(-HeelingAngle));
   SinHeel:=Sin(DegToRad(-HeelingAngle));
   CosTrim:=Cos(DegToRad(-TrimAngle));
   SinTrim:=Sin(DegToRad(-TrimAngle));

   Calculated:=False;   // Resets all data and calculated variables
   // Calculate the definition of the waterlineplane
   Keel:=SetPoint(0.0,0.0,Owner.FindLowestHydrostaticsPoint);
   FData.WaterlinePlane:=WaterlinePlane;

   // In order to calculate the volume enclosed by the underwatership correctly,
   // the origin (0.0, 0.0, 0.0) is projected onto the waterline plane
   NewOrigin:=ProjectPointOnPlane(ZERO,FData.WaterlinePlane);

   // Now calculate the actual volume
   Submerged:=False;
   PointCapacity:=5;
   Setlength(Points,PointCapacity);
   FData.AbsoluteDraft:=1000;
   FirstPoint:=True;
   for I:=1 to Owner.NumberOfLayers do
   begin
      Layer:=Owner.Layer[I-1];
      if Layer.UseInHydrostatics then for J:=1 to Layer.Count do
      begin
         Face:=Layer.Items[J-1];
         for K:=1 to Face.ChildCount do
         begin
            Child:=Face.Child[K-1];
            // Calculate the portside of the model
            NoPoints:=0;
            P1:=Child.Point[Child.NumberOfPoints-1].Coordinate;
            // calculate on which side of the waterplane this point is
            Side1:=FData.Waterlineplane.A*P1.x+FData.Waterlineplane.B*P1.y+FData.Waterlineplane.C*P1.z+FData.Waterlineplane.D;
            for L:=1 to Child.NumberOfPoints do
            begin
               P2:=Child.Point[L-1].Coordinate;
               Side2:=FData.Waterlineplane.A*P2.x+FData.Waterlineplane.B*P2.y+FData.Waterlineplane.C*P2.z+FData.Waterlineplane.D;
               if ((Side1<-1e-5) and (Side2>1e-5)) or ((Side1>1e-5) and (Side2<-1e-5)) then
               begin
                  // The current linesegment between P1-P2 intersects the waterlineplae
                  if Side1=Side2 then Parameter:=0.5*(Side1+Side2)
                                 else Parameter:=-Side1/(Side2-Side1);
                  P.X:=P1.X+Parameter*(P2.X-P1.X);
                  P.Y:=P1.Y+Parameter*(P2.Y-P1.Y);
                  P.Z:=P1.Z+Parameter*(P2.Z-P1.Z);
                  Inc(NoPoints);
                  if NoPoints>PointCapacity then
                  begin
                     inc(PointCapacity);
                     Setlength(Points,PointCapacity);
                  end;
                  Points[NoPoints-1]:=P;
               end;
               if Side2<=1e-5 then
               begin
                  if Side2<FData.AbsoluteDraft then FData.AbsoluteDraft:=Side2;
                  // P2 lies also on or under the waterlineplane
                  Inc(NoPoints);
                  if NoPoints>PointCapacity then
                  begin
                     inc(PointCapacity);
                     Setlength(Points,PointCapacity);
                  end;
                  Points[NoPoints-1]:=P2;
                  if Side2<-1e-5 then
                  begin
                     // point is submerged, check if the model is making water
                     if (Child.Point[L-1].IsBoundaryVertex) and (abs(Child.Point[L-1].Coordinate.Y)>1e-4) then
                     begin
                        if not (feMakingWater in Errors) then
                        begin
                           Errors:=Errors+[feMakingwater];
                           FData.Leak:=Child.Point[L-1].Coordinate;
                        end;
                     end;
                  end;
               end;
               P1:=P2;
               Side1:=Side2;
            end;

            // calculate volume aft of this face
            if NoPoints>2 then Submerged:=True;
            for L:=3 to NoPoints do ProcessTriangle(Points[0],Points[L-2],Points[L-1]);

            if Layer.Symmetric then
            begin
               // Calculate the starboardside of the model
               NoPoints:=0;
               P1:=Child.Point[Child.NumberOfPoints-1].Coordinate;
               P1.Y:=-P1.Y;
               // calculate on which side of the waterplane this point is
               Side1:=FData.Waterlineplane.A*P1.x+FData.Waterlineplane.B*P1.y+FData.Waterlineplane.C*P1.z+FData.Waterlineplane.D;
               for L:=1 to Child.NumberOfPoints do
               begin
                  P2:=Child.Point[L-1].Coordinate;
                  P2.Y:=-P2.Y;
                  Side2:=FData.Waterlineplane.A*P2.x+FData.Waterlineplane.B*P2.y+FData.Waterlineplane.C*P2.z+FData.Waterlineplane.D;
                  if ((Side1<-1e-5) and (Side2>1e-5)) or ((Side1>1e-5) and (Side2<-1e-5)) then
                  begin
                     // The current linesegment between P1-P2 intersects the waterlineplae
                     if Side1=Side2 then Parameter:=0.5*(Side1+Side2)
                                    else Parameter:=-Side1/(Side2-Side1);
                     P.X:=P1.X+Parameter*(P2.X-P1.X);
                     P.Y:=P1.Y+Parameter*(P2.Y-P1.Y);
                     P.Z:=P1.Z+Parameter*(P2.Z-P1.Z);
                     Inc(NoPoints);
                     if NoPoints>PointCapacity then
                     begin
                        inc(PointCapacity);
                        Setlength(Points,PointCapacity);
                     end;
                     Points[NoPoints-1]:=P;
                  end;
                  if Side2<=1e-5 then
                  begin
                     // P2 lies also under the waterlineplane
                     if Side2<FData.AbsoluteDraft then FData.AbsoluteDraft:=Side2;
                     Inc(NoPoints);
                     if NoPoints>PointCapacity then
                     begin
                        inc(PointCapacity);
                        Setlength(Points,PointCapacity);
                     end;
                     Points[NoPoints-1]:=P2;
                     if Side2<-1e-5 then
                     begin
                        // point is submerged, check if the model is making water
                        if (Child.Point[L-1].IsBoundaryVertex) and (abs(Child.Point[L-1].Coordinate.Y)>1e-4) then
                        begin
                           if not (feMakingWater in Errors) then
                           begin
                              Errors:=Errors+[feMakingwater];
                              FData.Leak:=Child.Point[L-1].Coordinate;
                           end;
                        end;
                     end;
                  end;
                  P1:=P2;
                  Side1:=Side2;
               end;
               // calculate volume aft of this face
               if NoPoints>2 then Submerged:=True;
               for L:=3 to NoPoints do ProcessTriangle(Points[0],Points[L-1],Points[L-2],);
            end;
         end;
      end;
   end;
   FData.AbsoluteDraft:=-FData.AbsoluteDraft;
   if FirstPoint then
   begin
      // No intersection with the watersurface found, the ship is either
      // not submerged or totally submerged
      if not submerged then
      begin
         Errors:=Errors+[feNothingSubmerged];
         FData.AbsoluteDraft:=0.0;
      end;
   end;
   if feMakingWater in Errors then
   begin
      FData.Volume:=0.0;
      FData.CenterOfBuoyancy:=ZERO;
   end;
   if FData.Volume<>0 then
   begin
      // Translate center of buoyancy back to the original origin
      FData.CenterOfBuoyancy.X:=NewOrigin.X+FData.CenterOfBuoyancy.X/FData.Volume;
      FData.CenterOfBuoyancy.Y:=NewOrigin.Y+FData.CenterOfBuoyancy.Y/FData.Volume;
      FData.CenterOfBuoyancy.Z:=NewOrigin.Z+FData.CenterOfBuoyancy.Z/FData.Volume;
      FData.CenterOfBuoyancy:=RotatePoint(FData.CenterOfBuoyancy);
      if FData.LengthWaterline<>0 then FData.LCBPerc:=100*((FData.CenterOfBuoyancy.X-Owner.ProjectSettings.ProjectMainframeLocation)/FData.LengthWaterline);
      // Apply appendage coeff.
      FData.Displacement:=VolumeToDisplacement(FData.Volume,Owner.ProjectSettings.ProjectWaterDensity,Owner.ProjectSettings.ProjectAppendageCoefficient,Owner.ProjectSettings.ProjectUnits);
      FData.Volume:=FData.Volume*Owner.ProjectSettings.ProjectAppendageCoefficient;

   end;
   Calculated:=True;
end;{TFreeHydrostaticCalc.CalculateVolume}

procedure TFreeHydrostaticCalc.Clear;
begin
   Calculated:=False;
   FHydrostaticType:=fhShort;
   FHeelingAngle:=0.0;
   FTrim:=0.0;
   FDraft:=0.0;
   Fillchar(FData,SizeOf(FData),0);
   FMainframe.Clear;
   FCalculations:=[hcAll];
end;{TFreeHydrostaticCalc.Clear}

constructor TFreeHydrostaticCalc.Create(Owner:TFreeShip);
begin
   Inherited create;
   FOwner:=Owner;
   FMainframe:=TFreeIntersection.Create(Owner);
   Owner.FHydrostaticCalculations.Add(self);
   Clear;
end;{TFreeHydrostaticCalc.Create}

destructor TFreeHydrostaticCalc.Destroy;
var Index : integer;
begin
   Clear;
   Index:=Owner.FHydrostaticCalculations.IndexOf(self);
   if Index<>-1 then Owner.FHydrostaticCalculations.Delete(Index);
   FMainframe.Destroy;
   Inherited Destroy;
end;{TFreeHydrostaticCalc.Destroy}

procedure TFreeHydrostaticCalc.ShowData(Mode:TFreeHydrostaticsMode);
var Strings : TStringlist;
    Dialog  : TFreeHydrostaticsDialog;
    I       : integer;
begin
   if not Calculated then Calculate;
   Strings:=TStringlist.Create;
   AddData(Strings,Mode,';');
   Dialog:=TFreeHydrostaticsDialog.Create(Owner);
   ShowTranslatedValues(Dialog);
   try
      Dialog.Edit.Lines.BeginUpdate;
      Dialog.Edit.Clear;
      for I:=1 to Strings.Count do Dialog.Edit.Lines.Add(Strings.Strings[I-1]);
   finally
      Dialog.Edit.Lines.EndUpdate;
      Strings.Destroy;
      Dialog.ShowModal;
      Dialog.Destroy;
   end;
end;{TFreeHydrostaticCalc.ShowData}

{---------------------------------------------------------------------------------------------------}
{                                       TFreeIntersection                                           }
{                                                                                                   }
{   TFreeIntersection is a list of curves calculated from the intersection of a                     }
{   ship hull (represented by a subdivision surface) and a plane.                                   }
{   This plane can be a orthogonal plane (eg. stations, waterlines, buttocks) or a freely oriented  }
{   3D plane (sent)                                                                                 }
{---------------------------------------------------------------------------------------------------}
procedure TFreeIntersection.DeleteItem(Item:TFreeSpline);
var Index:integer;
begin
   Index:=FItems.IndexOf(Item);
   if Index<>-1 then
   begin
      FItems.Delete(index);
   end;
   Item.Destroy;
end;{TFreeIntersection.DeleteItem}

function TFreeIntersection.FGetColor:TColor;
begin
   Case IntersectionType of
      fiStation   : Result:=Owner.Preferences.StationColor;
      fiButtock   : Result:=Owner.Preferences.ButtockColor;
      fiWaterline : Result:=Owner.Preferences.WaterlineColor;
      fiDiagonal  : Result:=Owner.Preferences.DiagonalColor;
      else Result:=clWhite;
   end;
end;{TFreeIntersection.FGetColor}

function TFreeIntersection.FGetPlane:T3DPlane;
begin
   Result:=FPlane;
end;{TFreeIntersection.FGetPlane}

function TFreeIntersection.FGetCount:integer;
begin
   if self=nil then result:=0
               else Result:=FItems.Count;
end;{TFreeIntersection.FGetCount}

function TFreeIntersection.FGetDescription:string;
begin
   Case IntersectionType of
      fiStation : Result:=Userstring(58);
      fiButtock : Result:=Userstring(59);
      fiWaterline : Result:=Userstring(60);
      fiDiagonal : Result:=Userstring(61);
      else Result:='Free';
   end;
   if IntersectionType=fiDiagonal then Result:=Result+#32+FloatToStrF(-FPLane.d/FPlane.c,ffFixed,7,3)
                                  else Result:=Result+#32+FloatToStrF(-FPLane.d,ffFixed,7,3);
end;{TFreeIntersection.FGetDescription}

function TFreeIntersection.FGetItem(Index:integer):TFreeSpline;
begin
   Result:=FItems.Items[Index];
end;{TFreeIntersection.FGetItem}

procedure TFreeIntersection.FSetBuild(Val:Boolean);
var I : integer;
begin
   if not Val then
   begin
      for I:=1 to Count do Items[I-1].Destroy;
      FItems.Clear;
   end;
   FBuild:=Val;
end;{TFreeIntersection.FSetBuild}

procedure TFreeIntersection.Add(Item:TFreeSpline);
begin
   FItems.Add(Item);
end;{TFreeIntersection.Add}

procedure TFreeIntersection.CalculateArea(Plane:T3DPlane;var Area:TFloatType;var COG:T3DCoordinate;var MomentOfInertia:T2DCoordinate);
var I       : Integer;
    TmpArea : TFloatType;
    TmpCOG  : T3DCoordinate;
    MomI    : T3DCoordinate;

   procedure CalculateSplineArea(Spline:TFreeSpline;var SplineArea:TFloatType;Var SplineCOG,MomInertia:T3DCoordinate);
   var ClosedSpline     : Boolean;
       IntersectionData : TFreeIntersectionData;
       Parameters       : TFloatArray;
       I,J              : Integer;
       NoPoints         : Integer;
       T1,T2,T,Side     : TFloatType;
       DeltaA           : TFloatType;
       P                : T3DCoordinate;
       P1,P2,C          : T2DCoordinate;
       MomI             : T2DCoordinate;

       function ProjectTo2D(P:T3DCoordinate):T2DCoordinate;
       begin
          Case IntersectionType of
             fiStation     : begin
                                Result.X:=P.Y;
                                Result.Y:=P.Z;
                             end;
             fiButtock     : begin
                                Result.X:=P.X;
                                Result.Y:=P.Z;
                             end;
             fiWaterline   : begin
                                Result.X:=P.X;
                                Result.Y:=P.Y;
                             end;
             else
             begin
               Result.X:=0.0;
               Result.Y:=0.0;
             end;
          end;
       end;{ProjectTo2D}

   begin
      SplineArea:=0.0;
      SplineCOG:=ZERO;
      MomInertia:=ZERO;
      C.X:=0.0;
      C.Y:=0.0;
      MomI:=C;
      ClosedSpline:=DistPP3D(Spline.Point[0],Spline.Point[Spline.NumberOfPoints-1])<1e-4;
      if not ClosedSpline then
      begin
         // make it closed
         Spline.Add(Spline.Point[0]);
         Spline.Knuckle[Spline.NumberOfPoints-2]:=True;
      end;
      Spline.Fragments:=500;
      NoPoints:=2;
      Setlength(Parameters,2);
      Parameters[0]:=0.0;
      Parameters[1]:=1.0;
      if IntersectionType<>fiWaterline then if Spline.IntersectPlane(Plane,IntersectionData) then
      begin
         Setlength(Parameters,NoPoints+Intersectiondata.NumberOfIntersections);
         for I:=1 to Intersectiondata.NumberOfIntersections do
         begin
            Parameters[NoPoints]:=Intersectiondata.Parameters[I-1];
            Inc(NoPoints);
         end;
      end;
      SortFloatArray(Parameters,NoPoints);
      if NoPoints>0 then
      begin
         T1:=0.0;
         for I:=2 to NoPoints do
         begin
            T2:=Parameters[I-1];
            T:=0.5*(T1+T2);
            P:=Spline.Value(T);
            // check on which side of the plane this point is
            Side:=Plane.a*P.x+Plane.b*P.y+Plane.c*P.z+Plane.d;
            if (Side<0) or (IntersectionType=fiWaterline) then
            begin
               // The point lies at the back of the plane, include this area
               for J:=0 to 500 do
               begin
                  T:=T1+(J/500)*(T2-T1);
                  P:=Spline.Value(T);
                  P2:=ProjectTo2D(P);
                  if J>0 then
                  begin
                     DeltaA:=0.5*(P2.X+P1.X)*(P2.Y-P1.Y);
                     SplineArea:=SplineArea+DeltaA;
                     C.X:=C.X+DeltaA*0.25*(P2.X+P1.X);
                     C.Y:=C.Y+DeltaA*0.50*(P2.Y+P1.Y);
                     MomI.X:=MomI.X+(1.0/12.0)*(P1.Y+P2.Y)*(P1.Y*P1.Y+P2.Y*P2.Y)*(P2.X-P1.X);
                     MomI.Y:=MomI.Y+(1.0/12.0)*(P2.X*P2.X*(3*P2.Y+P1.Y)+2*P1.X*P2.X*(P1.Y+P2.Y)+P1.X*P1.X*(3*P1.Y+P2.Y))*(P2.X-P1.X);
                  end;
                  P1:=P2;
               end;
            end;
            T1:=T2;
         end;
         if SplineArea<>0.0 then
         begin
            C.X:=C.X/SplineArea;
            C.Y:=C.Y/SplineArea;
            MomI.X:=abs(MomI.X);
            MomI.Y:=abs(MomI.Y);
            Case IntersectionType of
               fiStation    : begin
                                 SplineCOG.X:=-FPlane.d;
                                 SplineCOG.Y:=C.X;
                                 SplineCOG.Z:=C.Y;
                                 MomInertia.X:=0;
                                 MomInertia.Y:=MomI.X;
                                 MomInertia.Z:=MomI.Y;
                              end;
               fiButtock    : begin
                                 SplineCOG.X:=C.X;
                                 SplineCOG.Y:=-FPlane.d;
                                 SplineCOG.Z:=C.Y;
                                 MomInertia.X:=MomI.X;
                                 MomInertia.Z:=MomI.Y;
                                 MomInertia.Y:=0;
                              end;
               fiWaterline  : begin
                                 SplineCOG.X:=C.X;
                                 SplineCOG.Y:=C.Y;
                                 SplineCOG.Z:=-FPlane.d;
                                 MomInertia.X:=MomI.X;
                                 MomInertia.Y:=MomI.Y;
                                 MomInertia.Z:=0;
                              end;

            end;
         end;

      end;
   end;{CalculateSplineArea}

begin
   Area:=0.0;
   COG:=ZERO;
   MomentOfInertia.X:=0;
   MomentOfInertia.Y:=0;
   if not Build then Rebuild;
   if Count>0 then
   begin
      CreateStarboardPart; // This also ensures coreect winding order
      for I:=1 to Count do
      begin
         CalculateSplineArea(Items[I-1],TmpArea,TmpCOG,MomI);
         Area:=Area+TmpArea;
         COG.X:=COG.X+TmpArea*TmpCOG.X;
         COG.Y:=COG.Y+TmpArea*TmpCOG.Y;
         COG.Z:=COG.Z+TmpArea*TmpCOG.Z;
      end;
      if Area<>0.0 then
      begin
         COG.X:=COG.X/Area;
         COG.Y:=COG.Y/Area;
         COG.Z:=COG.Z/Area;
         if IntersectionType=fiWaterline then
         begin
            MomentOfInertia.X:=MomI.X-COG.Y*COG.Y*Area;
            MomentOfInertia.Y:=MomI.Y-COG.X*COG.X*Area;
         end;
      end;
   end;
   if (Count=0) or (Area=0) then
   begin
      COG:=ZERO;
      Case IntersectionType of
           fiStation    : COG.X:=-FPlane.d;
           fiButtock    : COG.Y:=-FPlane.d;
           fiWaterline  : COG.Z:=-FPlane.d;
      end;
   end;
end;{TFreeIntersection.CalculateArea}

procedure TFreeIntersection.Clear;
var I : integer;
begin
   for I:=1 to Count do Items[I-1].Destroy;
   FItems.Clear;
   FBuild:=False;
   FShowCurvature:=False;
   FUseHydrostaticsSurfacesOnly:=False
end;{TFreeIntersection.Clear}

constructor TFreeIntersection.Create(Owner:TFreeShip);
begin
   inherited Create;
   FOwner:=Owner;
   FItems:=TFasterList.Create;
   Clear;
end;{TFreeIntersection.Create}

// Create the starboardhalf of the ship, for use in hydrostatic calculations
procedure TFreeIntersection.CreateStarboardPart;
var I,J     : integer;
    Spline  : TFreeSpline;
    P1,P2   : T3DCoordinate;
    Area    : TFloatType;
    DeltaA  : TFloatType;
begin
   if self.IntersectionType<>fiButtock then
   begin
      // Copy all present splines and mirror the y-coordinate
      FItems.Capacity:=FItems.Count*2;
      for I:=Count downto 1 do
      begin
         Spline:=TFreeSpline.Create;
         Spline.Assign(Items[I-1]);
         for J:=1 to Spline.NumberOfPoints do
         begin
            P1:=Spline.Point[J-1];
            P1.Y:=-P1.Y;
            Spline.Point[J-1]:=P1;
         end;
         FItems.Add(Spline);
      end;
      // Try to connect the splines
      JoinSplineSegments(0.05,False,FItems);
   end;
   // Check if the orientation is counterclockwise
   for I:=Count downto 1 do
   begin
      Spline:=Items[I-1];
      Area:=0;
      P1:=Spline.Point[Spline.NumberOfPoints-1];
      for J:=0 to 500 do
      begin
         P2:=Spline.Value(J/500);
         Case IntersectionType of
            fiStation   : DeltaA:=0.5*(P2.Y+P1.Y)*(P2.Z-P1.Z);
            fiButtock   : DeltaA:=0.5*(P2.X+P1.X)*(P2.Z-P1.Z);
            fiWaterline : DeltaA:=0.5*(P2.X+P1.X)*(P2.Y-P1.Y);
            else Raise exception.Create(Userstring(66)+'!');
         end;
         Area:=Area+DeltaA;
         P1:=P2;
      end;
      if (abs(Area)<1e-4) and (Count>0) then
      begin
         // Either this spline has a very small area(0.01m x 0.01m) or it is an unconnected
         // straight line. In both cases it may be deleted as long as at least one valid
         // spline segment remains.
         Spline.Destroy;
         FItems.Delete(I-1);
      end else if Area<0 then
      begin
         // spline is defined clockwise, so invert the controlpoints
         Spline.InvertDirection;
      end;
   end;
end;{TFreeIntersection.CreateStarboardPart}

procedure TFreeIntersection.Delete;
var Index : integer;
begin
   Case IntersectionType of
      fiStation : begin
                     Index:=Owner.FStations.IndexOf(self);
                     if Index<>-1 then
                     begin
                        Owner.FStations.Delete(Index);
                        Owner.FileChanged:=True;
                        if Redraw then Owner.Redraw;
                        Destroy;
                     end;
                  end;
      fiButtock : begin
                     Index:=Owner.FButtocks.IndexOf(self);
                     if Index<>-1 then
                     begin
                        Owner.FButtocks.Delete(Index);
                        Owner.FileChanged:=True;
                        if Redraw then Owner.Redraw;
                        Destroy;
                     end;
                  end;
      fiWaterline: begin
                     Index:=Owner.FWaterlines.IndexOf(self);
                     if Index<>-1 then
                     begin
                        Owner.FWaterlines.Delete(Index);
                        Owner.FileChanged:=True;
                        if Redraw then Owner.Redraw;
                        Destroy;
                     end;
                  end;
      fiDiagonal : begin
                     Index:=Owner.FDiagonals.IndexOf(self);
                     if Index<>-1 then
                     begin
                        Owner.FDiagonals.Delete(Index);
                        Owner.FileChanged:=True;
                        if Redraw then Owner.Redraw;
                        Destroy;
                     end;
                  end;

   end;
end;{TFreeIntersection.Delete}

destructor TFreeIntersection.Destroy;
begin
   Clear;
   FItems.Destroy;
   Inherited Destroy;
end;{TFreeIntersection.Destroy}

procedure TFreeIntersection.Draw(Viewport:TFreeViewport);
var I,J     : integer;
    Spline  : TFreeSpline;
    P,P2,N  : T3DCoordinate;
    Pts     : array of TPoint;
    CPts    : array of TPoint;
    Curv    : TFloatType;
    R,G,B   : integer;
    DrawIt  : Boolean;

begin
   if Viewport.ViewportMode=vmWireframe then
   begin
      if not Build then Rebuild;
      for I:=1 to Count do
      begin
         Spline:=Items[I-1];
         Spline.Color:=Color;
         Spline.PenStyle:=psSolid;
         if IntersectionType=fiStation then if Viewport.ViewType in [fvProfile,fvPlan] then Spline.PenStyle:=psDot;
         if IntersectionType=fiButtock then if Viewport.ViewType in [fvBodyplan,fvPlan] then Spline.PenStyle:=psDot;
         if IntersectionType=fiWaterline then if Viewport.ViewType in [fvProfile,fvBodyplan] then Spline.PenStyle:=psDot;
         if Spline.PenStyle=psDot then Spline.Color:=clSilver;

         Spline.CurvatureColor:=Owner.Preferences.CurvaturePlotColor;
         Spline.CurvatureScale:=Owner.Visibility.CurvatureScale;
         Spline.ShowCurvature:=(Owner.Visibility.ShowCurvature) and (ShowCurvature);;
         if Spline.ShowCurvature then Spline.Fragments:=800
                                 else Spline.Fragments:=600;

         Setlength(Pts,Spline.Fragments+1);
         if Spline.ShowCurvature then Setlength(CPts,Spline.Fragments+1);
         // Draw portside
         DrawIt:=IntersectionType in [fiButtock,fiWaterline,fiDiagonal];
         if IntersectionType=fiStation then Drawit:=(Viewport.ViewType<>fvBodyplan) or (Owner.Visibility.ModelView=mvBoth) or (Spline.Max.X>=Owner.ProjectSettings.ProjectMainframeLocation);
         {
         if IntersectionType=fiStation then
         begin
            P:=Spline.Value(0.0);
            P.Y:=0.0;
            Pts[0]:=Viewport.Project(P);
            for J:=1 to Spline.Fragments-1 do
            begin
               P:=Spline.Value((J-1)/(Spline.Fragments-2));
               Pts[J]:=Viewport.Project(P);
            end;
            P.Y:=0.0;
            Pts[Spline.Fragments]:=Viewport.Project(P);
            Viewport.BrushColor:=clGreen;
            Viewport.BrushStyle:=bsSolid;
            Viewport.PenColor:=Spline.Color;
            Viewport.PenStyle:=Spline.PenStyle;
            Viewport.DrawingCanvas.Polygon(Pts);
         end else
         }
         if DrawIt then
         begin
            for J:=0 to Spline.Fragments do
            begin
               if Spline.ShowCurvature then
               begin
                  Curv:=Spline.Curvature(J/Spline.Fragments,P,N);
                  Pts[J]:=Viewport.Project(P);
                  P2.X:=P.X-Curv*Spline.CurvatureScale*N.X;
                  P2.Y:=P.Y-Curv*Spline.CurvatureScale*N.Y;
                  P2.Z:=P.Z-Curv*Spline.CurvatureScale*N.Z;
                  CPts[J]:=Viewport.Project(P2);
               end else
               begin
                  P:=Spline.Value(J/Spline.Fragments);
                  Pts[J]:=Viewport.Project(P);
               end;
            end;
            if Spline.ShowCurvature then
            begin
               Viewport.SetPenWidth(1);
               Viewport.PenColor:=Spline.CurvatureColor;
               Viewport.PenStyle:=psSolid;
               for J:=0 to Spline.Fragments do if (J mod 10=0) or (J=0) or (J=Spline.Fragments) then
               begin
                  Viewport.DrawingCanvas.MoveTo(Pts[J].X,Pts[J].Y);
                  Viewport.DrawingCanvas.LineTo(CPts[J].X,CPts[J].Y);
               end;
               Viewport.DrawingCanvas.Polyline(CPts);
            end;
            Viewport.PenColor:=Spline.Color;
            Viewport.PenStyle:=Spline.PenStyle;
            Viewport.DrawingCanvas.Polyline(Pts);
         end;

         DrawIt:=False;
         if (Owner.Visibility.ModelView=mvBoth) then DrawIt:=True
            else if (Viewport.ViewType=fvBodyplan) and (Spline.Max.X<=Owner.ProjectSettings.ProjectMainframeLocation) then DrawIt:=True;
         if DrawIt then
         begin
            // Draw starboard side
            for J:=0 to Spline.Fragments do
            begin
               if Spline.ShowCurvature then
               begin
                  Curv:=Spline.Curvature(J/Spline.Fragments,P,N);
                  N.Y:=-N.Y;
                  P.Y:=-P.Y;
                  Pts[J]:=Viewport.Project(P);
                  P2.X:=P.X-Curv*Spline.CurvatureScale*N.X;
                  P2.Y:=P.Y-Curv*Spline.CurvatureScale*N.Y;
                  P2.Z:=P.Z-Curv*Spline.CurvatureScale*N.Z;
                  CPts[J]:=Viewport.Project(P2);
               end else
               begin
                  P:=Spline.Value(J/Spline.Fragments);
                  P.Y:=-P.Y;
                  Pts[J]:=Viewport.Project(P);
               end;
            end;
            if Spline.ShowCurvature then
            begin
               Viewport.SetPenWidth(1);
               Viewport.PenColor:=Spline.CurvatureColor;
               Viewport.PenStyle:=psSolid;
               for J:=0 to Spline.Fragments do if (J mod 10=0) or (J=0) or (J=Spline.Fragments) then
               begin
                  Viewport.DrawingCanvas.MoveTo(Pts[J].X,Pts[J].Y);
                  Viewport.DrawingCanvas.LineTo(CPts[J].X,CPts[J].Y);
               end;
               Viewport.DrawingCanvas.Polyline(CPts);
            end;
            Viewport.PenColor:=Spline.Color;
            Viewport.PenStyle:=Spline.PenStyle;
            Viewport.DrawingCanvas.Polyline(Pts);
         end;
         
      end;
   end else
   begin
      // draw to z-buffer
      if not Build then Rebuild;
      R:=GetRValue(Color);
      G:=GetGValue(Color);
      B:=GetBValue(Color);
      for I:=1 to Count do
      begin
         Spline:=Items[I-1];
         Spline.Fragments:=250;
         P:=Spline.Value(0.0);
         for J:=1 to Spline.Fragments do
         begin
            P2:=Spline.Value(J/Spline.Fragments);
            Viewport.DrawLineToZBuffer(P,P2,R,G,B);
            P:=P2;
         end;
         if Owner.Visibility.ModelView=mvBoth then
         begin
            // Draw starboardside as well
            P:=Spline.Value(0.0);
            P.Y:=-P.Y;
            for J:=1 to Spline.Fragments do
            begin
               P2:=Spline.Value(J/Spline.Fragments);
               P2.Y:=-P2.Y;
               Viewport.DrawLineToZBuffer(P,P2,R,G,B);
               P:=P2;
            end;
         end;
      end;
   end;
end;{TFreeIntersection.Draw}

procedure TFreeIntersection.DrawAll;
var I : integer;
begin
   for I:=1 to Owner.NumberOfViewports do Draw(Owner.Viewport[I-1]);
end;{TFreeIntersection.DrawAll}

procedure TFreeIntersection.Extents(Var Min,Max:T3DCoordinate);
var I    : integer;
begin
   if not build then Rebuild;
   for I:=1 to Count do Items[I-1].Extents(Min,Max);
end;{TFreeIntersection.Extents}

procedure TFreeIntersection.LoadBinary(Source:TFreeFileBuffer);
var I,J,M,N : integer;
    Spline  : TFreeSpline;
    P       : T3DCoordinate;
    Bool    : Boolean;
begin
   Source.Load(I);
   FIntersectionType:=TFreeIntersectionType(I);
   if Owner.FileVersion>=fv191 then
   begin
      Source.Load(FShowCurvature);
   end else FShowCurvature:=False;
   Source.Load(FPlane);
   Source.Load(FBuild);
   Source.Load(N);
   FItems.Capacity:=N;
   for I:=1 to N do
   begin
      Spline:=TFreeSpline.Create;
      FItems.Add(Spline);
      // Read number of points for this spline
      Source.Load(M);
      // Read actual 3D coordinates
      Spline.Capacity:=M;
      for J:=1 to M do
      begin
         if Owner.FileVersion>=fv160 then
         begin
            if IntersectionType=fiStation then
            begin
               P.X:=-FPlane.d;
               Source.Load(P.Y);
               Source.Load(P.Z);
            end else if IntersectionType=fiButtock then
            begin
               Source.Load(P.X);
               P.Y:=-FPlane.d;
               Source.Load(P.Z);
            end else if IntersectionType=fiWaterline then
            begin
               Source.Load(P.X);
               Source.Load(P.Y);
               P.Z:=-FPlane.d;
            end else Source.Load(P);
         end else Source.Load(P);
         Spline.Add(P);
         Source.Load(Bool);
         Spline.Knuckle[J-1]:=Bool;
      end;
   end;
end;{TFreeIntersection.LoadBinary}

procedure TFreeIntersection.Rebuild;
var I:Integer;
begin
   // Force to destroy all current Items
   Build:=false;
   Owner.Surface.IntersectPlane(Plane,FUseHydrostaticsSurfacesOnly,FItems);
   // Use a low simplification factor to remove only points that are (nearly) on a line
   if Owner.ProjectSettings.ProjectSimplifyIntersections then for I:=1 to Count do self.Items[I-1].Simplify(2.0);
   Build:=true;
end;{TFreeIntersection.Rebuild}

procedure TFreeIntersection.SaveToDXF(Strings:TStringList);
var I      : integer;
    Layer  : string;
    Spline : TFreeSpline;
begin
   if not build then Rebuild;
   for I:=1 to count do
   begin
      Spline:=Items[I-1];
      Case IntersectionType of
         fiStation   : layer:=Userstring(62);
         fiButtock   : layer:=Userstring(63);
         fiWaterline : layer:=Userstring(64);
         fiDiagonal  : layer:=Userstring(65);
         else Layer:='Layer_0';
      end;
      case Owner.Precision of
         fpLow      : Spline.Fragments:=50;
         fpMedium   : Spline.Fragments:=100;
         fpHigh     : Spline.Fragments:=150;
         fpVeryHigh : Spline.Fragments:=500;
         else Spline.Fragments:=100;
      end;
      Spline.SaveToDXF(Strings,Layer,Owner.Visibility.ModelView=mvBoth);
   end;
end;{TFreeIntersection.SaveToDXF}

procedure TFreeIntersection.SaveBinary(Destination:TFreeFileBuffer);
var I,J     : integer;
    Spline  : TFreeSpline;
    P       : T3DCoordinate;
begin
   Destination.Add(Ord(FIntersectionType));
   if Owner.FileVersion>=fv191 then
   begin
      Destination.Add(FShowCurvature);
   end;
   Destination.Add(FPlane);
   Destination.Add(FBuild);
   Destination.Add(Count);
   for I:=1 to Count do
   begin
      Spline:=Items[I-1];
      Destination.Add(Spline.NumberOfPoints);
      for J:=1 to Spline.NumberOfPoints do
      begin
         P:=Spline.Point[J-1];
         if Owner.FileVersion>=fv160 then
         begin
            Case IntersectionType of
               fiStation    : begin
                                 Destination.Add(P.Y);
                                 Destination.Add(P.Z);
                                 Destination.Add(Spline.Knuckle[J-1]);
                              end;
               fiButtock    : begin
                                 Destination.Add(P.X);
                                 Destination.Add(P.Z);
                                 Destination.Add(Spline.Knuckle[J-1]);
                              end;
               fiWaterline  : begin
                                 Destination.Add(P.X);
                                 Destination.Add(P.Y);
                                 Destination.Add(Spline.Knuckle[J-1]);
                              end;
               fiDiagonal   : begin
                                 Destination.Add(P);
                                 Destination.Add(Spline.Knuckle[J-1]);
                              end;
            end;
         end else
         begin
            Destination.Add(P);
            Destination.Add(Spline.Knuckle[J-1]);
         end;
      end;
   end;
end;{TFreeIntersection.SaveBinary}

{---------------------------------------------------------------------------------------------------}
{                                           TFreeMarker                                             }
{---------------------------------------------------------------------------------------------------}
function TFreeMarker.FGetSelected:Boolean;
begin
   Result:=Owner.FSelectedMarkers.SortedIndexOf(self)<>-1;
end;{TFreeMarker.FGetSelected}

procedure TFreeMarker.FSetSelected(val:Boolean);
var Index : Integer;
begin
   Index:=Owner.FSelectedMarkers.SortedIndexOf(self);
   if Val then
   begin
      // Only add if it is not already in the list
      if Index=-1 then Owner.FSelectedMarkers.AddSorted(self);
   end else
   begin
      if Index<>-1 then Owner.FSelectedMarkers.Delete(index);
   end;
   if Assigned(Owner.Surface.OnSelectItem) then Owner.Surface.OnSelectItem(self);
end;{TFreeMarker.FSetSelected}

procedure TFreeMarker.Clear;
begin
   FVisible:=True;
   inherited Clear;
end;{TFreeMarker.Clear}

function TFreeMarker.DistanceToCursor(X,Y:Integer;Viewport:TFreeViewport):integer;
var I,Tmp    : Integer;
    Pt,P1,P2 : TPoint;
    V1,V2    : T3DCoordinate;
    Param    : TFloatType;
begin
   Result:=1000000;
   if (Viewport.ViewType=fvBodyPlan) and (not (Owner.Visibility.ModelView=mvBoth)) then
   begin
      // Check if cursor position lies within the boundaries
      Pt.X:=X;
      Pt.Y:=Y;
      if (Pt.X>=0) and (Pt.X<=Viewport.Width) and (Pt.Y>=0) and (Pt.Y<=Viewport.Height) then
      begin
         V1:=Value(0.0);
         if V1.X<Owner.ProjectSettings.ProjectMainframeLocation then V1.Y:=-V1.Y;
         for I:=1 to Fragments do
         begin
            V2:=Value((I-1)/(Fragments-1));
            if V2.X<Owner.ProjectSettings.ProjectMainframeLocation then V2.Y:=-V2.Y;
            if ((V1.X<Owner.ProjectSettings.ProjectMainframeLocation) and (V2.X<Owner.ProjectSettings.ProjectMainframeLocation)) or
               ((V1.X>Owner.ProjectSettings.ProjectMainframeLocation) and (V2.X>Owner.ProjectSettings.ProjectMainframeLocation)) then
            begin
               P1:=Viewport.Project(V1);
               P2:=Viewport.Project(V2);
               Tmp:=Round(DistanceToLine(P1,P2,X,Y,Param));
               if Tmp<Result then result:=Tmp;
            end;
            P1:=P2;
            V1:=V2;
         end;
      end;
   end else Result:=inherited DistanceToCursor(X,Y,Viewport);
   if Owner.Visibility.ModelView=mvBoth then
   begin
      for I:=1 to NumberOfPoints do
      begin
         V1:=Point[I-1];
         V1.Y:=-V1.Y;
         Point[I-1]:=V1;
      end;
      try
         Tmp:=inherited DistanceToCursor(X,Y,Viewport);
         if Tmp<Result then Result:=Tmp;
      finally
         for I:=1 to NumberOfPoints do
         begin
            V1:=Point[I-1];
            V1.Y:=-V1.Y;
            Point[I-1]:=V1;
         end;
      end;
   end;
end;{TFreeMarker.DistanceToCursor}

procedure TFreeMarker.Delete;
var Index:Integer;
begin
   Index:=Owner.FSelectedMarkers.SortedIndexOf(Self);
   if Index<>-1 then Owner.FSelectedMarkers.Delete(Index);
   Index:=Owner.FMarkers.IndexOf(Self);
   if Index<>-1 then Owner.FMarkers.Delete(Index);
   Destroy;
end;{TFreeMarker.Delete}

procedure TFreeMarker.Draw(Viewport:TFreeViewport);
var I,J,Size: Integer;
    Scale   : Integer;
    Pt      : TPoint;
    Plane   : T3DPlane;
    Output  : TFreeIntersectionData;
    Param   : TFloatArray;
    NParam  : Integer;
    P3D,P2  : T3DCoordinate;
    Normal  : T3DCoordinate;
    PArray1 : array of TPoint;
    PArray2 : array of TPoint;
    Fragm   : Integer;
    C,T     :TFloatType;
begin
   if Visible then
   begin
      if Owner<>nil then
      begin
         if Selected then Color:=Owner.Preferences.SelectColor
                     else Color:=owner.Preferences.MarkerColor;
         Size:=Owner.Preferences.PointSize;
      end else
      begin
         Color:=clLime;
         Size:=2;
         MessageDlg(Userstring(67),mtError,[mbOk],0);
      end;
      Fragments:=250;
      if (Viewport.ViewType=fvBodyPlan) and (Owner.Visibility.ModelView<>mvBoth) then
      begin
         Plane:=SetPlane(1.0,0.0,0.0,-Owner.ProjectSettings.ProjectMainframeLocation);
         NParam:=2;
         Setlength(Param,NParam);
         Param[0]:=0.0;
         Param[1]:=1.0;
         if IntersectPlane(Plane,Output) then
         begin
            Setlength(Param,NParam+Output.NumberOfIntersections);
            for I:=1 to Output.NumberOfIntersections do
            begin
               Param[NParam]:=Output.Parameters[I-1];
               inc(NParam);
            end;
            SortFloatArray(Param,NParam);
         end;
         for I:=2 to NParam do
         begin
            P3D:=Value(0.5*(Param[I-2]+Param[I-1]));
            if P3D.X<Owner.ProjectSettings.ProjectMainframeLocation then Scale:=-1
                                                                    else scale:=1;
            Fragm:=Round((Param[I-1]-Param[I-2])*Fragments);
            if Fragm<10 then Fragm:=10;
            if ShowCurvature then
            begin
               SetLength(PArray1,Fragm);
               SetLength(PArray2,Fragm);
               for J:=1 to Fragm do
               begin
                  T:=Param[I-2]+(Param[I-1]-Param[I-2])*(J-1)/(Fragm-1);
                  C:=Curvature(T,P3D,Normal);
                  P3D.Y:=P3D.Y*Scale;
                  Normal.Y:=Normal.Y*Scale;
                  PArray1[J-1]:=Viewport.Project(P3D);
                  P2.X:=P3D.X-C*2*CurvatureScale*Normal.X;
                  P2.Y:=P3D.Y-C*2*CurvatureScale*Normal.Y;
                  P2.Z:=P3D.Z-C*2*CurvatureScale*Normal.Z;
                  PArray2[J-1]:=Viewport.Project(P2);
               end;
               Viewport.SetPenWidth(1);
               Viewport.PenColor:=CurvatureColor;
               for J:=1 to Fragm do if (J mod 4=0) or (J=1) or (J=Fragm) then
               begin
                  Viewport.DrawingCanvas.MoveTo(PArray1[J-1].X,PArray1[J-1].Y);
                  Viewport.DrawingCanvas.LineTo(PArray2[J-1].X,PArray2[J-1].Y);
               end;
               Viewport.DrawingCanvas.Polyline(PArray2);
            end else
            begin
               SetLength(PArray1,Fragm);
               for J:=1 to Fragm do
               begin
                  T:=Param[I-2]+(Param[I-1]-Param[I-2])*(J-1)/(Fragm-1);
                  P3D:=Value(T);
                  P3D.Y:=P3D.Y*Scale;
                  PArray1[J-1]:=Viewport.Project(P3D);
               end;
            end;
            Viewport.SetPenWidth(1);
            Viewport.PenColor:=Color;
            Viewport.DrawingCanvas.Pen.Style:=Penstyle;
            Viewport.DrawingCanvas.Polyline(PArray1);
         end;
         for I:=1 to NumberOfPoints do
         begin
            P3D:=Point[I-1];
            if P3D.X<Owner.ProjectSettings.ProjectMainframeLocation then P3D.Y:=-P3D.Y;
            Pt:=Viewport.Project(P3D);
            Viewport.DrawingCanvas.MoveTo(Pt.X-Size,Pt.Y-Size);
            Viewport.DrawingCanvas.LineTo(Pt.X+Size,Pt.Y+Size);
            Viewport.DrawingCanvas.MoveTo(Pt.X-Size,Pt.Y+Size);
            Viewport.DrawingCanvas.LineTo(Pt.X+Size,Pt.Y-Size);
         end;
      end else
      begin
         inherited Draw(Viewport);
         for I:=1 to NumberOfPoints do
         begin
            Pt:=Viewport.Project(Point[I-1]);
            Viewport.DrawingCanvas.MoveTo(Pt.X-Size,Pt.Y-Size);
            Viewport.DrawingCanvas.LineTo(Pt.X+Size,Pt.Y+Size);
            Viewport.DrawingCanvas.MoveTo(Pt.X-Size,Pt.Y+Size);
            Viewport.DrawingCanvas.LineTo(Pt.X+Size,Pt.Y-Size);
         end;
      end;
   end;
end;{TFreeMarker.Draw}

procedure TFreeMarker.LoadBinary(Source:TFreeFileBuffer);
var sel:boolean;
begin
   Source.Load(FVisible);
   if Owner.FileVersion>=fv260 then
   begin
      Source.Load(Sel);
      if sel then Owner.FSelectedMarkers.AddSorted(self);
   end;
   Inherited LoadBinary(Source);
end;{TFreeMarker.LoadBinary}

procedure TFreeMarker.SaveBinary(Destination:TFreeFileBuffer);
begin
   Destination.Add(FVisible);
   if Owner.FileVersion>=fv260 then
   begin
      Destination.Add(Selected);
   end;
   Inherited SaveBinary(Destination);
end;{TFreeMarker.SaveBinary}

{---------------------------------------------------------------------------------------------------}
{                                           TFreeFlowline                                           }
{---------------------------------------------------------------------------------------------------}
function TFreeFlowline.FGetColor:TColor;
begin
   if Selected then result:=Owner.Preferences.SelectColor
      else if FMethodNew then result:=clRed
          else Result:=clBlue;
end;{TFreeFlowline.FGetColor}

function TFreeFlowline.FGetSelected:Boolean;
begin
   Result:=Owner.FSelectedFlowlines.SortedIndexOf(self)<>-1;
end;{TFreeFlowline.FGetSelected}

function TFreeFlowline.FGetVisible:Boolean;
begin
   Result:=owner.Visibility.ShowFlowlines;
end;{TFreeFlowline.FGetVisible}

procedure TFreeFlowline.FSetSelected(val:Boolean);
var Index : Integer;
begin
   Index:=Owner.FSelectedFlowlines.SortedIndexOf(self);
   if Val then
   begin
      // Only add if it is not already in the list
      if Index=-1 then Owner.FSelectedFlowlines.AddSorted(self);
   end else
   begin
      if Index<>-1 then Owner.FSelectedFlowlines.Delete(index);
   end;
   if Assigned(Owner.Surface.OnSelectItem) then Owner.Surface.OnSelectItem(self);
end;{TFreeFlowline.FSetSelected}

procedure TFreeFlowline.FSetBuild(val:Boolean);
begin
   FBuild:=val;
   if not Build then FFlowline.Clear;
end;{TFreeFlowline.FSetBuild}

procedure TFreeFlowline.Clear;
begin
   FProjectionPoint.X:=0;
   FProjectionPoint.Y:=0;
   FProjectionView:=fvProfile;
   FFlowLine.Clear;
   FBuild:=false;
   FMethodNew:=False;
end;{TFreeFlowline.Clear}

constructor TFreeFlowline.Create(Owner:TFreeShip);
begin
   inherited Create;
   FOwner:=owner;
   FFlowLine:=TFreespline.Create;
   Clear;
end;{TFreeFlowline.Create}

procedure TFreeFlowline.Delete;
var Index:Integer;
begin
   Index:=Owner.FSelectedFlowlines.SortedIndexOf(Self);
   if Index<>-1 then Owner.FSelectedFlowlines.Delete(Index);
   Index:=Owner.FFlowLines.IndexOf(Self);
   if Index<>-1 then Owner.FFlowlines.Delete(Index);
   Destroy;
end;{TFreeFlowline.Delete}

destructor TFreeFlowline.Destroy;
begin
   Clear;
   FFlowLine.Destroy;
   Inherited Destroy;
end;{TFreeFlowline.Destroy}

function TFreeFlowline.DistanceToCursor(X,Y:Integer;Viewport:TFreeViewport):integer;
var I,Tmp    : Integer;
    Pt,P1,P2 : TPoint;
    V1,V2    : T3DCoordinate;
    Param    : TFloatType;
begin
   Result:=1000000;
   if (Viewport.ViewType=fvBodyPlan) and (not (Owner.Visibility.ModelView=mvBoth)) then
   begin
      // Check if cursor position lies within the boundaries
      Pt.X:=X;
      Pt.Y:=Y;
      if (Pt.X>=0) and (Pt.X<=Viewport.Width) and (Pt.Y>=0) and (Pt.Y<=Viewport.Height) then
      begin
         V1:=FFlowline.Value(0.0);
         if V1.X<Owner.ProjectSettings.ProjectMainframeLocation then V1.Y:=-V1.Y;
         for I:=1 to FFlowline.Fragments do
         begin
            V2:=FFlowline.Value((I-1)/(FFlowline.Fragments-1));
            if V2.X<Owner.ProjectSettings.ProjectMainframeLocation then V2.Y:=-V2.Y;
            if ((V1.X<Owner.ProjectSettings.ProjectMainframeLocation) and (V2.X<Owner.ProjectSettings.ProjectMainframeLocation)) or
               ((V1.X>Owner.ProjectSettings.ProjectMainframeLocation) and (V2.X>Owner.ProjectSettings.ProjectMainframeLocation)) then
            begin
               P1:=Viewport.Project(V1);
               P2:=Viewport.Project(V2);
               Tmp:=Round(DistanceToLine(P1,P2,X,Y,Param));
               if Tmp<Result then result:=Tmp;
            end;
            P1:=P2;
            V1:=V2;
         end;
      end;
   end else Result:=FFlowline.DistanceToCursor(X,Y,Viewport);
   if Owner.Visibility.ModelView=mvBoth then
   begin
      for I:=1 to FFlowline.NumberOfPoints do
      begin
         V1:=FFlowline.Point[I-1];
         V1.Y:=-V1.Y;
         FFlowline.Point[I-1]:=V1;
      end;
      try
         Tmp:=FFlowline.DistanceToCursor(X,Y,Viewport);
         if Tmp<Result then Result:=Tmp;
      finally
         for I:=1 to FFlowline.NumberOfPoints do
         begin
            V1:=FFlowline.Point[I-1];
            V1.Y:=-V1.Y;
            FFlowline.Point[I-1]:=V1;
         end;
      end;
   end;
end;{TFreeFlowline.DistanceToCursor}

procedure TFreeFlowline.Draw(Viewport:TFreeViewport);
var I,J     : Integer;
    Scale   : Integer;
    Size    : Integer;
    Plane   : T3DPlane;
    Output  : TFreeIntersectionData;
    Param   : TFloatArray;
    NParam  : Integer;
    P3D     : T3DCoordinate;
    PArray1 : array of TPoint;
    Pt      : TPoint;
    Fragm   : Integer;
    T       : TFloatType;
begin
   if not build then rebuild;
   FFlowline.Color:=Color;
   FFlowline.Fragments:=600;
   if (FFlowline.NumberOfPoints>0) and (Viewport.ViewportMode=vmWireframe) then
   begin
      // draw flowline source
      P3D:=FFlowline.Point[0];
      if (Viewport.ViewType=fvBodyplan) and (Owner.Visibility.ModelView<>mvBoth) and (P3D.X<Owner.ProjectSettings.ProjectMainframeLocation) then P3D.Y:=-P3D.Y;
      Pt:=Viewport.Project(P3D);
      Size:=Round(Sqrt(Viewport.Zoom)*(Owner.Preferences.PointSize+1));
      if size<1 then size:=1;
      Viewport.BrushStyle:=bsClear;
      if Viewport.Printing then Size:=round(Size*Viewport.PrintResolution/150);
      Viewport.PenColor:=clDkGray;
      Viewport.BrushColor:=clWhite;
      Viewport.BrushStyle:=bsSolid;
      // Draw entire circle in white;
      Viewport.DrawingCanvas.Ellipse(Pt.X-Size,Pt.Y-Size,Pt.X+Size,Pt.Y+Size);
      if Owner.Visibility.ModelView=mvBoth then
      begin
         P3D.Y:=-P3D.Y;
         Pt:=Viewport.Project(P3D);
         // Draw entire circle in white;
         Viewport.DrawingCanvas.Ellipse(Pt.X-Size,Pt.Y-Size,Pt.X+Size,Pt.Y+Size);
      end;
   end;


   if (Viewport.ViewType=fvBodyPlan) and (Owner.Visibility.ModelView<>mvBoth) then
   begin
      Plane:=SetPlane(1.0,0.0,0.0,-Owner.ProjectSettings.ProjectMainframeLocation);
      NParam:=2;
      Setlength(Param,NParam);
      Param[0]:=0.0;
      Param[1]:=1.0;
      if FFlowline.IntersectPlane(Plane,Output) then
      begin
         Setlength(Param,NParam+Output.NumberOfIntersections);
         for I:=1 to Output.NumberOfIntersections do
         begin
            Param[NParam]:=Output.Parameters[I-1];
            inc(NParam);
         end;
         SortFloatArray(Param,NParam);
      end;
      for I:=2 to NParam do
      begin
         P3D:=FFlowline.Value(0.5*(Param[I-2]+Param[I-1]));
         if P3D.X<Owner.ProjectSettings.ProjectMainframeLocation then Scale:=-1
                                                                 else scale:=1;
         Fragm:=Round((Param[I-1]-Param[I-2])*FFlowline.Fragments);
         if Fragm<10 then Fragm:=10;
         SetLength(PArray1,Fragm);
         for J:=1 to Fragm do
         begin
            T:=Param[I-2]+(Param[I-1]-Param[I-2])*(J-1)/(Fragm-1);
            P3D:=FFlowline.Value(T);
            P3D.Y:=P3D.Y*Scale;
            PArray1[J-1]:=Viewport.Project(P3D);
         end;
         Viewport.SetPenWidth(1);
         Viewport.PenColor:=FFlowline.Color;
         Viewport.DrawingCanvas.Pen.Style:=FFlowline.Penstyle;
         Viewport.DrawingCanvas.Polyline(PArray1);
      end;
   end else
   begin
      FFlowline.Draw(Viewport);
      if Owner.Visibility.ModelView=mvBoth then
      begin
         for I:=1 to FFlowline.NumberOfPoints do
         begin
            P3D:=FFlowline.Point[I-1];
            P3D.Y:=-P3D.Y;
            FFlowline.Point[I-1]:=P3D;
         end;
         try
            FFlowline.Draw(Viewport);
         finally
            for I:=1 to FFlowline.NumberOfPoints do
            begin
               P3D:=FFlowline.Point[I-1];
               P3D.Y:=-P3D.Y;
               FFlowline.Point[I-1]:=P3D;
            end;
         end;
      end;
   end;
end;{TFreeFlowline.Draw}

procedure TFreeFlowline.LoadBinary(Source:TFreeFileBuffer);
var I,N : Integer;
    P   : T3DCoordinate;
    K   : Boolean;
begin
   Source.Load(FProjectionPoint.X);
   Source.Load(FProjectionPoint.Y);
   Source.Load(I);
   FProjectionView:=TFreeviewType(I);
   Source.Load(FBuild);
   Source.load(K);
   if K then Owner.FSelectedFlowlines.AddSorted(self);
   Source.Load(N);
   FFlowline.Capacity:=N;
   for I:=1 to N do
   begin
      Source.Load(P);
      Source.Load(K);
      FFlowline.Add(P);
      FFlowline.Knuckle[FFlowline.NumberOfPoints-1]:=K;
   end;
end;{TFreeFlowline.LoadBinary}

procedure TFreeFlowline.Rebuild;
type TTriangle  = record
                     P1,P2,P3 : Integer;
                     Plane    : T3DPlane;
                     Index    : Integer;
                     Processed: Boolean;
                  end;
     TPointData = record
                     Coord     : T3DCoordinate;
                     FlowDir   : T3DCoordinate;
                     Triangles : array of integer;
                     Ntriangles: Integer;
                  end;

var Points     : TFasterList;
    Faces      : TFasterList;
    Face       : TFreeSubdivisionControlFace;
    Point      : TFreeSubdivisionPoint;
    Child      : TFreeSubdivisionFace;
    I,J,K,L    : Integer;
    Index      : Integer;
    Layer      : TFreeSubdivisionLayer;
    WlHeight   : TFloatType;
    Triangles  : array of TTriangle;
    NTriangles : Integer;
    Iteration  : Integer;
    Skip1,Skip2:integer;
    TriangleCapacity:Integer;
    PointData  : array of TPointData;
    StartPoint : T3DCoordinate;
    EndPoint   : T3DCoordinate;
    Intersection:T3DCoordinate;
    Direction  : T3DCoordinate;
    Valid      : Boolean;

    procedure AddTriangleToPoint(var Point:TPointData;TriangleIndex:Integer);
    begin
       inc(Point.Ntriangles);
       Setlength(Point.Triangles,Point.Ntriangles);
       Point.Triangles[Point.Ntriangles-1]:=TriangleIndex;
    end;{AddTriangleToPoint}

    procedure AddTriangle(P1,P2,P3:TFreeSubdivisionPoint);
    begin
       if NTriangles=TriangleCapacity then
       begin
         inc(TriangleCapacity,250);
         Setlength(Triangles,TriangleCapacity);
       end;
       Triangles[NTriangles].Index:=NTriangles;
       Triangles[NTriangles].Processed:=False;
       Triangles[NTriangles].P1:=Points.SortedIndexOf(P1);
       AddTriangleToPoint(PointData[Triangles[NTriangles].P1],NTriangles);
       Triangles[NTriangles].P2:=Points.SortedIndexOf(P2);
       AddTriangleToPoint(PointData[Triangles[NTriangles].P2],NTriangles);
       Triangles[NTriangles].p3:=Points.SortedIndexOf(P3);
       AddTriangleToPoint(PointData[Triangles[NTriangles].P3],NTriangles);
       Triangles[NTriangles].Plane:=PlanePPP(P1.Coordinate,P2.Coordinate,P3.Coordinate);
       inc(NTriangles);
    end;{AddTriangle}

    function CalculateFlowDirection2(Incoming:T3DCoordinate;Point:TFreeSubdivisionPoint):T3DCoordinate;
    var Normal    : T3DCoordinate;
        Direction : T3DCoordinate;
        P,Proj    : T3DCoordinate;
        Plane     : T3DPlane;
    begin
       //Incoming.x:=Incoming.x-1.001;
       //Incoming.x:=Incoming.X-1.001;
       //Incoming.y:=0.4*Incoming.y;
       //Incoming.z:=0.4*Incoming.z;
       Incoming:=Normalize(Incoming);
       Normal:=Point.Normal;
       P:=Point.Coordinate;
       Plane:=PlanePointNormal(P,Normal);
       Direction:=Normalize(AddPoint(Normal,Incoming));
       Incoming:=AddPoint(P,Direction);
       Proj:=ProjectPointOnPlane(Incoming,Plane);
       Direction:=Subtract(Proj,P);
       Result:=Normalize(Direction);
    end;{CalculateFlowDirection2}

    function CalculateFlowDirection(Point:TFreeSubdivisionPoint):T3DCoordinate;
    var V : T3DCoordinate;
    begin
       V:=SetPoint(-1,0,0);
       Result:=CalculateFlowDirection2(V,Point);
    end;{CalculateFlowDirection}

    function FindInitialTriangle(StartPoint,EndPoint:T3DCoordinate;var Int,Dir:T3DCoordinate):Integer;
    var I         : Integer;
        Triangle  : TTriangle;
        S1,S2,s,t : TFloatType;
        P,u,v,w   : T3DCoordinate;
        P0,P1,P2  : T3DCoordinate;
        Distance  : Double;
        b0,b1,b2  : Double;
        UdotV     : Double;
        UdotU     : Double;
        VdotV     : Double;
        WdotU     : Double;
        WdotV     : Double;
    begin
       Result:=-1;
       Distance:=1e8;
       Int:=Zero;
       Dir:=Zero;
       for I:=1 to NTriangles do
       begin
          Triangle:=Triangles[I-1];
          S1:=Triangle.Plane.a*StartPoint.x+Triangle.Plane.b*StartPoint.y+Triangle.Plane.c*StartPoint.z+Triangle.Plane.d;
          S2:=Triangle.Plane.a*EndPoint.x+Triangle.Plane.b*EndPoint.y+Triangle.Plane.c*EndPoint.z+Triangle.Plane.d;
          if ((S1<0) and (S2>0)) or ((S1>0) and (S2<0)) then
          begin
             // possible intersection
             if S1=S2 then T:=0.5
                      else T:=-s1/(s2-s1);
             P.X:=StartPoint.X+T*(EndPoint.X-StartPoint.X);
             P.Y:=StartPoint.Y+T*(EndPoint.Y-StartPoint.Y);
             P.Z:=StartPoint.Z+T*(EndPoint.Z-StartPoint.Z);
             if PointInTriangle(P,PointData[Triangle.P1].Coord,PointData[Triangle.P2].Coord,PointData[Triangle.P3].Coord) then
             begin
                T:=DistPP3D(StartPoint,P);
                if T<Distance then
                begin
                   Distance:=T;
                   Result:=I-1;
                   Int:=P;
                end;
             end;
          end;
       end;
       if Result<>-1 then
       begin
          // Calculate baycentric coordinates to interpolate between the three flowdirections
          // http://softsurfer.com/Archive/algorithm_0104/algorithm_0104.htm
          Triangle:=Triangles[result];
          P0:=PointData[Triangle.P1].Coord;
          P1:=PointData[Triangle.P2].Coord;
          P2:=PointData[Triangle.P3].Coord;
          u:=Subtract(P1,P0);
          v:=Subtract(P2,P0);
          w:=Subtract(Int,P0);
          UdotU:=Dotproduct(U,U);
          UdotV:=Dotproduct(U,V);
          VdotV:=Dotproduct(V,V);
          WdotU:=Dotproduct(W,U);
          WdotV:=Dotproduct(W,V);
          s:=(UdotV*WdotV-VdotV*WdotU)/(UdotV*UdotV-UdotU*VdotV);
          t:=(UdotV*WdotU-UdotU*WdotV)/(UdotV*UdotV-UdotU*VdotV);
          b0:=1-s-t;
          b1:=s;
          b2:=t;
          // check
          t:=b0+b1+b2;
          if T=1 then
          begin
             P0:=PointData[Triangle.P1].FlowDir;
             P1:=PointData[Triangle.P2].FlowDir;
             P2:=PointData[Triangle.P3].FlowDir;
             Dir.X:=b0*P0.X+b1*P1.X+b2*P2.X;
             Dir.Y:=b0*P0.Y+b1*P1.Y+b2*P2.Y;
             Dir.Z:=b0*P0.Z+b1*P1.Z+b2*P2.Z;

             if FMethodNew then
             begin
                Dir:=Normalize(SetPoint(-1,0.1,-0.1));
             end;
          end else
          begin
             Result:=Result-1+1;
          end;
       end;
    end;{FindInitialTriangle}

    function ProcessTriangle(var Triangle:TTriangle;var SkipInd1,SkipInd2:Integer;var Intersection,Direction:T3DCoordinate;var NextTriangle:integer):boolean;
    var P1,P2     : T3DCoordinate;
        Dir1,Dir2 : T3DCoordinate;
        Ind1,Ind2 : Integer;
        I         : Integer;
        Int       : T3DCoordinate;
        Distance  : TFloatType;
        Param     : double;

        function NextTriangleIndex(P1,P2,CurrIndex:Integer):Integer;
        var Point1,Point2:TPointData;
            I,J          : Integer;
        begin
           Result:=-1;
           Point1:=PointData[P1];
           Point2:=PointData[P2];
           for I:=1 to Point1.Ntriangles do
           begin
              for J:=1 to Point2.Ntriangles do
              begin
                 if (Point1.Triangles[I-1]=Point2.Triangles[J-1]) and
                    (Point1.Triangles[I-1]<>CurrIndex) then
                 begin
                    Result:=Point1.Triangles[I-1];
                    exit;
                 end;
              end;
           end;
        end;{NextTriangleIndex}

    begin
       Result:=False;
       NextTriangle:=Triangle.Index;
       Triangle.Processed:=True;

       P1:=ProjectPointOnPlane(Intersection,Triangle.Plane);
       P1.X:=P1.X+0.0005*Direction.X;
       P1.Y:=P1.Y+0.0005*Direction.Y;
       P1.Z:=P1.Z+0.0005*Direction.Z;
       if not PointInTriangle(P1,PointData[Triangle.P1].Coord,PointData[Triangle.P2].Coord,PointData[Triangle.P3].Coord) then
       begin
          P1:=ProjectPointOnPlane(Intersection,Triangle.Plane);
       end;

       P1:=ProjectPointOnPlane(P1,Triangle.Plane);

       Distance:=50;
       P2.X:=P1.X+Distance*Direction.X;
       P2.Y:=P1.Y+Distance*Direction.Y;
       P2.Z:=P1.Z+Distance*Direction.Z;
       P2:=ProjectPointOnPlane(P2,Triangle.Plane);
       // test all three linesegments for intersection

       for I:=1 to 3 do
       begin
          Case I of
             1 : Ind1:=Triangle.P1;
             2 : Ind1:=Triangle.P2;
             3 : Ind1:=Triangle.P3;
             Else Ind1:=0;
          end;
          Case I of
             1 : Ind2:=Triangle.P2;
             2 : Ind2:=Triangle.P3;
             3 : Ind2:=Triangle.P1;
             else Ind2:=0;
          end;
          if ((Ind1=SkipInd1) and (Ind2=SkipInd2)) or ((Ind1=SkipInd2) and (Ind2=SkipInd1)) then
          begin
          end else if Lines3DIntersect(P1,P2,PointData[Ind1].Coord,PointData[Ind2].Coord,Param,Int) then
          begin
             Distance:=Triangle.Plane.a*Int.x+Triangle.Plane.b*Int.y+Triangle.Plane.c*Int.z+Triangle.Plane.d;
             if Distance<1e-1 then
             begin
               Intersection:=Int;
               // calculate direction
               if FMethodNew then
               begin
                  Dir1:=CalculateFlowDirection2(Direction,Points[Ind1]);
                  Dir2:=CalculateFlowDirection2(Direction,Points[Ind2]);
               end else
               begin
                  Dir1:=PointData[Ind1].FlowDir;
                  Dir2:=PointData[Ind2].FlowDir;
               end;
               SkipInd1:=Ind1;
               SkipInd2:=ind2;
               Direction.X:=Dir1.X+Param*(Dir2.X-Dir1.X);
               Direction.Y:=Dir1.Y+Param*(Dir2.Y-Dir1.Y);
               Direction.Z:=Dir1.Z+Param*(Dir2.Z-Dir1.Z);
               NextTriangle:=NextTriangleIndex(ind1,Ind2,Triangle.Index);
               Result:=True;
               Exit;
             end;
          end;
       end;
    end;{ProcessTriangle}

begin
   // clear any present data
   Build:=false;

   // Assemble all faces that are (partially) submerged and extract points
   Faces:=TFasterList.Create;
   WlHeight:=Owner.FindLowestHydrostaticsPoint+Owner.ProjectSettings.ProjectDraft;

   //wlheight:=owner.surface.max.z;

   if Owner.surface.NumberOfPoints<0 then exit;
   for I:=1 to Owner.Surface.NumberOfLayers do if Owner.Surface.Layer[I-1].UseInHydrostatics then
   begin
      Layer:=Owner.Surface.Layer[I-1];
      for J:=1 to Layer.Count do if Layer.Items[J-1].Min.Z<=WlHeight then
      begin
         Face:=Layer.Items[J-1];
         for K:=1 to Face.ChildCount do
         begin
            Child:=Face.Child[K-1];
            for L:=1 to Child.NumberOfpoints do if Child.Point[L-1].Coordinate.Z<=WlHeight then
            begin
               // Face is (partially) submerged;
               Faces.Add(Child);
               break;
            end;
         end;
      end
   end;
   if Faces.Count>0 then
   begin
      Points:=TFasterList.create;
      Points.Capacity:=Faces.Count+100;
      for I:=1 to Faces.Count do
      begin
         Child:=Faces[I-1];
         for J:=1 to Child.NumberOfpoints do
         begin
            Point:=Child.Point[J-1];
            if Points.SortedIndexOf(Point)=-1 then Points.AddSorted(Point);
         end;
      end;
      Points.Sort;
      Setlength(PointData,Points.Count);
      for I:=1 to Points.Count do
      begin
         Point:=Points[I-1];
         PointData[I-1].Coord:=Point.Coordinate;
         PointData[I-1].FlowDir:=CalculateFlowDirection(Point);
         PointData[I-1].Ntriangles:=0;
      end;

      TriangleCapacity:=2*Faces.Count;
      Setlength(Triangles,TriangleCapacity);
      NTriangles:=0;
      for I:=1 to Faces.Count do
      begin
         Child:=Faces[I-1];
         for J:=3 to Child.NumberOfpoints do AddTriangle(Child.Point[0],Child.Point[J-2],Child.Point[J-1]);
      end;

      Case FProjectionView of
         fvProfile : begin
                        Startpoint.X:=FProjectionPoint.X;
                        StartPoint.Y:=Owner.Surface.Max.Y+10;
                        StartPoint.Z:=FProjectionPoint.Y;
                        EndPoint:=setPoint(StartPoint.X,0,StartPoint.Z);
                     end;
         fvPlan    : begin
                        Startpoint.X:=FProjectionPoint.X;
                        StartPoint.Y:=FProjectionPoint.Y;
                        StartPoint.Z:=Owner.Surface.Min.Z-10;
                        EndPoint:=setPoint(StartPoint.X,StartPoint.Y,Owner.Surface.Max.Z+100);
                     end;
         fvBodyplan: if FProjectionPoint.X<0 then
                     begin
                        Startpoint.X:=Owner.Surface.Min.X-10;
                        StartPoint.Y:=-FProjectionPoint.X;
                        StartPoint.Z:=FProjectionPoint.Y;
                        EndPoint:=setPoint(Owner.Surface.Max.X+10,StartPoint.Y,StartPoint.Z);
                     end else
                     begin
                        Startpoint.X:=Owner.Surface.Max.X+10;
                        StartPoint.Y:=FProjectionPoint.X;
                        StartPoint.Z:=FProjectionPoint.Y;
                        EndPoint:=setPoint(Owner.Surface.Min.X-10,StartPoint.Y,StartPoint.Z);
                     end;
      end;

      // find the initial triangle
      Index:=FindInitialTriangle(StartPoint,EndPoint,Intersection,Direction);
      Skip1:=-1;
      Skip2:=-1;
      if index<>-1 then
      begin
         FFlowline.Add(Intersection);
         // trace triangles from here
         Iteration:=0;
         repeat
            if Triangles[index].Processed then Valid:=False
                                          else Valid:=ProcessTriangle(Triangles[index],Skip1,Skip2,Intersection,Direction,Index);
            if Valid then
            begin
               FFlowline.Add(Intersection);
            end else
            begin
               Valid:=ProcessTriangle(Triangles[index],Skip1,Skip2,Intersection,Direction,Index);
            end;
            inc(Iteration);
         until (not valid) or (index=-1) or (Iteration>5000);
         While FFlowline.NumberOfPoints>1 do
         begin
            if (FFlowline.Point[FFlowline.NumberOfPoints-1].Z>WlHeight) and (FFlowline.Point[FFlowline.NumberOfPoints-2].Z>WlHeight) then
            begin
               FFlowline.DeletePoint(FFlowline.NumberOfPoints-1);
            end else if (FFlowline.Point[FFlowline.NumberOfPoints-1].Z>WlHeight) and (FFlowline.Point[FFlowline.NumberOfPoints-2].Z<WlHeight) then
            begin
               Endpoint.X:=FFlowline.Point[FFlowline.NumberOfPoints-2].X+(FFlowline.Point[FFlowline.NumberOfPoints-1].X-FFlowline.Point[FFlowline.NumberOfPoints-2].X)*(WlHeight-FFlowline.Point[FFlowline.NumberOfPoints-2].Z)/(FFlowline.Point[FFlowline.NumberOfPoints-1].Z-FFlowline.Point[FFlowline.NumberOfPoints-2].Z);
               Endpoint.Y:=FFlowline.Point[FFlowline.NumberOfPoints-2].Y+(FFlowline.Point[FFlowline.NumberOfPoints-1].Y-FFlowline.Point[FFlowline.NumberOfPoints-2].Y)*(WlHeight-FFlowline.Point[FFlowline.NumberOfPoints-2].Z)/(FFlowline.Point[FFlowline.NumberOfPoints-1].Z-FFlowline.Point[FFlowline.NumberOfPoints-2].Z);
               EndPoint.Z:=wlHeight;
               FFlowline.Point[FFlowline.NumberOfPoints-1]:=EndPoint;
            end else break;
         end;
      end;
      Points.Destroy;
   end;
   Faces.Destroy;
   FBuild:=True;
end;{TFreeFlowline.Rebuild}

procedure TFreeFlowline.SaveBinary(Destination:TFreeFileBuffer);
var I:Integer;
begin
   Destination.Add(FProjectionPoint.X);
   Destination.Add(FProjectionPoint.Y);
   Destination.Add(Ord(FProjectionView));
   Destination.Add(FBuild);
   Destination.Add(Selected);
   Destination.Add(FFlowline.NumberOfPoints);
   for I:=1 to FFlowline.NumberOfPoints do
   begin
      Destination.Add(FFlowline.Point[I-1]);
      Destination.Add(FFlowline.Knuckle[I-1]);
   end;
end;{TFreeFlowline.SaveBinary}

{---------------------------------------------------------------------------------------------------}
{                                       TFreeVisibility                                             }
{                                                                                                   }
{   This object stores all visibility options for the hull                                          }
{---------------------------------------------------------------------------------------------------}
procedure TFreeVisibility.FSetCurvatureScale(Val:TFloatType);
var I:Integer;
begin
   if abs(Val-FCurvatureScale)>1e-5 then
   begin
      FCurvatureScale:=Val;
      Owner.FileChanged:=True;
      For I:=1 to Owner.NumberOfViewports do if Owner.Viewport[I-1].ViewportMode=vmWireFrame then Owner.Viewport[I-1].Refresh
   end;
end;{TFreeVisibility.FSetCurvatureScale}

procedure TFreeVisibility.FSetCursorIncrement(val:TFloatType);
begin
   if Val<1e-5 then Val:=1e-5;
   if FCursorIncrement<>val then Owner.FileChanged:=True;
   FCursorIncrement:=val;
   if assigned(Owner.FOnChangeCursorIncrement) then Owner.FOnChangeCursorIncrement(self);
end;{TFreeVisibility.FSetCursorIncrement}

procedure TFreeVisibility.FSetModelView(Val:TFreeModelView);
begin
   if Val<>FModelView then
   begin
      FModelView:=Val;
      Owner.FileChanged:=True;
      Owner.Draw;
   end;
end;{TFreeVisibility.FSetModelView}

procedure TFreeVisibility.FSetShowInteriorEdges(Val:Boolean);
var I : Integer;
begin
   if Val<>FShowInteriorEdges then
   begin
      FShowInteriorEdges:=val;
      if not val then for I:=Owner.NumberOfSelectedControlFaces downto 1 do Owner.SelectedControlFace[I-1].Selected:=False;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;{TFreeVisibility.FSetShowInteriorEdges}

procedure TFreeVisibility.FSetShowControlNet(Val:Boolean);
var I : Integer;
begin
   if Val<>FShowControlNet then
   begin
      FShowControlNet:=val;
      if not FShowControlNet then
      begin
         for I:=Owner.NumberOfSelectedControlEdges downto 1 do Owner.SelectedControlEdge[I-1].Selected:=False;
         for I:=Owner.NumberOfSelectedControlPoints downto 1 do Owner.SelectedControlPoint[I-1].Selected:=False;
      end;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;{TFreeVisibility.FSetShowControlNet}

procedure TFreeVisibility.FSetShowCurvature(Val:Boolean);
begin
   if Val<>FShowCurvature then
   begin
      FShowCurvature:=val;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;{TVisibilityOptions.FSetShowCurvature}

procedure TFreeVisibility.FSetShowGrid(Val:Boolean);
begin
   if Val<>FShowGrid then
   begin
      FShowGrid:=val;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;{TFreeVisibility.FSetShowGrid}

procedure TFreeVisibility.FSetShowMarkers(Val:Boolean);
var I : Integer;
begin
   if Val<>FShowMarkers then
   begin
      FShowMarkers:=val;
      Owner.FileChanged:=True;
      if Owner.NumberofMarkers>0 then for I:=1 to Owner.NumberOfViewports do if Owner.Viewport[I-1].Zoom=1.0 then Owner.Viewport[I-1].ZoomExtents
                                                                                                             else Owner.Viewport[I-1].Refresh;
   end;
end;{TFreeVisibility.FSetShowMarkers}

procedure TFreeVisibility.FSetShowNormals(Val:Boolean);
begin
   if Val<>FShowNormals then
   begin
      FShowNormals:=val;
      Owner.FileChanged:=True;
      if Owner.NumberOfSelectedControlFaces>0 then Owner.Redraw;
   end;
end;{TFreeVisibility.FSetShowNormals}

procedure TFreeVisibility.FSetShowStations(Val:Boolean);
begin
   if Val<>FShowStations then
   begin
      FShowStations:=val;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;{TFreeVisibility.FSetShowStations}

procedure TFreeVisibility.FSetShowButtocks(Val:Boolean);
begin
   if Val<>FShowButtocks then
   begin
      FShowButtocks:=val;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;{TFreeVisibility.FSetShowButtocks}

procedure TFreeVisibility.FSetShowDiagonals(Val:Boolean);
begin
   if Val<>FShowDiagonals then
   begin
      FShowDiagonals:=val;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;{TFreeVisibility.FSetShowDiagonals}

procedure TFreeVisibility.FSetShowFlowlines(Val:Boolean);
begin
   if Val<>FShowFlowlines then
   begin
      FShowFlowlines:=val;
      if not FShowFlowlines then Owner.FSelectedFlowlines.Clear;
      Owner.FileChanged:=True;
      if Owner.NumberOfFlowLines>0 then Owner.Redraw;
   end;
end;{TFreeVisibility.FSetShowFlowlines}

procedure TFreeVisibility.FSetShowWaterlines(Val:Boolean);
begin
   if Val<>FShowWaterlines then
   begin
      FShowWaterlines:=val;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;{TFreeVisibility.FSetShowWaterlines}

procedure TFreeVisibility.FSetShowControlCurves(Val:Boolean);
var I:Integer;
begin
   if val<>FShowControlCurves then
   begin
      FShowControlCurves:=Val;
      if not val then for I:=Owner.Surface.NumberOfControlCurves downto 1 do Owner.Surface.ControlCurve[I-1].Selected:=False;
      if Owner.Surface.NumberOfControlCurves>0 then Owner.Redraw;
      Owner.Filechanged:=true;
   end;
end;{TFreeVisibility.FSetShowControlCurves}

procedure TFreeVisibility.FSetShowHydrostaticData(Val:Boolean);
begin
   if val<>FShowHydrostaticData then
   begin
      FShowHydrostaticData:=Val;
      Owner.Filechanged:=true;
      Owner.Redraw;
   end;
end;{TFreeVisibility.FSetShowHydrostaticData}

constructor TFreeVisibility.Create(Owner:TFreeShip);
begin
   inherited Create;
   FOwner:=Owner;
   Clear;
end;{TFreeVisibility.Create}

procedure TFreeVisibility.Clear;
begin
   FModelView:=mvPort;
   FShowInteriorEdges:=False;
   FShowControlNet:=True;
   FShowGrid:=True;
   FShowNormals:=True;
   FShowStations:=True;
   FShowbuttocks:=True;
   FShowWaterlines:=True;
   FShowDiagonals:=True;
   FShowMarkers:=True;
   FShowCurvature:=True;
   FShowControlCurves:=True;
   FCurvatureScale:=1.0;
   FCursorIncrement:=0.1;
   FShowHydrostaticData:=True;
   FShowHydrostDisplacement:=True;
   FShowHydrostLateralArea:=True;
   FShowHydrostSectionalAreas:=True;
   FShowHydrostMetacentricHeight:=True;
   FShowHydrostLCF:=True;
   FShowFlowlines:=True;
   if assigned(Owner.FOnChangeCursorIncrement) then Owner.FOnChangeCursorIncrement(self);
end;{TFreeVisibility.Clear}

procedure TFreeVisibility.DecreaseCurvatureScale;
begin
   CurvatureScale:=CurvatureScale/1.1;
end;{TFreeVisibility.DecreaseCurvatureScale}

procedure TFreeVisibility.IncreaseCurvatureScale;
begin
   CurvatureScale:=CurvatureScale*1.1;
end;{TFreeVisibility.IncreaseCurvatureScale}

procedure TFreeVisibility.LoadBinary(Source:TFreeFilebuffer);
var I : Integer;
begin
   Clear;
   Source.Load(I);
   FModelView:=TFreeModelView(I);
   Source.Load(FShowControlNet);
   Source.Load(FShowInteriorEdges);
   Source.Load(FShowStations);
   Source.Load(FShowButtocks);
   Source.Load(FShowWaterlines);
   Source.Load(FShowNormals);
   Source.Load(FShowGrid);
   Source.Load(FShowDiagonals);
   Source.Load(FShowMarkers);
   Source.Load(FShowCurvature);
   Source.Load(FCurvatureScale);
   if Owner.FileVersion>=fv195 then
   begin
      Source.Load(FShowControlCurves);
      if Owner.FileVersion>=fv210 then
      begin
         Source.Load(FCursorIncrement);
         if abs(FCursorIncrement)<1e-5 then FCursorIncrement:=0.1;
         if assigned(Owner.FOnChangeCursorIncrement) then Owner.FOnChangeCursorIncrement(self);
         if Owner.FileVersion>=fv220 then
         begin
            Source.Load(FShowHydrostaticData);
            Source.Load(FShowHydrostDisplacement);
            Source.Load(FShowHydrostLateralArea);
            Source.Load(FShowHydrostSectionalAreas);
            Source.Load(FShowHydrostMetacentricHeight);
            Source.Load(FShowHydrostLCF);
            if Owner.FileVersion>=fv250 then
            begin
               Source.Load(FShowFlowlines);
            end;
         end;
      end;
   end;
end;{TFreeVisibility.LoadBinary}

procedure TFreeVisibility.SaveBinary(Destination:TFreeFileBuffer);
begin
   Destination.Add(Ord(FModelView));
   Destination.Add(FShowControlNet);
   Destination.Add(FShowInteriorEdges);
   Destination.Add(FShowStations);
   Destination.Add(FShowButtocks);
   Destination.Add(FShowWaterlines);
   Destination.Add(FShowNormals);
   Destination.Add(FShowGrid);
   Destination.Add(FShowDiagonals);
   Destination.Add(FShowMarkers);
   Destination.Add(FShowCurvature);
   Destination.Add(FCurvatureScale);
   if Owner.FileVersion>=fv195 then
   begin
      Destination.Add(FShowControlCurves);
      if Owner.FileVersion>=fv210 then
      begin
         Destination.Add(FCursorIncrement);
         if Owner.FileVersion>=fv220 then
         begin
            Destination.Add(FShowHydrostaticData);
            Destination.Add(FShowHydrostDisplacement);
            Destination.Add(FShowHydrostLateralArea);
            Destination.Add(FShowHydrostSectionalAreas);
            Destination.Add(FShowHydrostMetacentricHeight);
            Destination.Add(FShowHydrostLCF);
            if Owner.FileVersion>=fv250 then
            begin
               Destination.Add(FShowFlowlines);
            end;
         end;
      end;
   end;
end;{TFreeVisibility.SaveBinary}

{---------------------------------------------------------------------------------------------------}
{                                       TFreeEdit                                                   }
{                                                                                                   }
{   Container class for all editing commandsns for the hull                                         }
{---------------------------------------------------------------------------------------------------}
function TFreeEdit.FGetRecentFile(Index:integer):string;
begin
   Result:=FRecentFiles[index];
end;{TFreeEdit.FGetRecentFile}

function TFreeEdit.FGetRecentFileCount:integer;
begin
   Result:=FRecentFiles.Count;
end;{TFreeEdit.FGetRecentFileCount}

// Takes a filename and adds it to the list with recent files
procedure TFreeEdit.AddToRecentFiles(Filename:String);
var I,Index       : integer;
    AlreadyPresent: Boolean;
    Tmp,Ext       : String;
begin
   AlreadyPresent:=false;
   Ext:=Uppercase(ExtractFileExt(Filename));

   Tmp:=ChangeFileExt(Filename,'');
   Tmp:=Trim(Tmp);
   for I:=1 to FRecentFiles.Count do
   begin
      if Uppercase(FRecentFiles[I-1])=Uppercase(Tmp) then
      begin
         Index:=I-1;
         AlreadyPresent:=True;
         // if not add the front of the list then move to the front;
         if Index<>0 then
         begin
            FRecentFiles.Delete(Index);
            FRecentFiles.Insert(0,Tmp);
         end;
      end;
   end;
   if not AlreadyPresent then
   begin
      // file not yet in the list, add at the front
      if FRecentFiles.Count=0 then FRecentFiles.Add(Tmp)
                              else FRecentFiles.Insert(0,Tmp);
   end;
   // delete items until no more than 10 are left
   while FRecentFiles.Count>10 do FRecentFiles.Delete(FRecentFiles.Count-1);
   if assigned(Owner.FOnUpdateRecentFileList) then Owner.FOnUpdateRecentFileList(self);
end;{TFreeEdit.AddToRecentFiles}

// Delete the backgrundimage associated with this view
procedure TFreeEdit.BackgroundImage_Delete(Viewport:TFreeViewport);
var I:Integer;
begin
   if MessageDlg(Userstring(68),mtConfirmation,[mbYes,mbNo],0)=mrYes then
   begin
      for I:=FOwner.NumberofBackgroundImages downto 1 do if FOwner.BackgroundImage[I-1].AssignedView=Viewport.ViewType then
      begin
         FOwner.BackgroundImage[I-1].Destroy;
         FOwner.FBackgroundImages.Delete(I-1);
         FOwner.FileChanged:=True;
         break;
      end;
      for I:=1 to FOwner.NumberOfViewports do if Owner.Viewport[I-1].ViewType=Viewport.ViewType then
      begin
         Owner.Viewport[I-1].BackgroundImage.Clear;
         Owner.Viewport[I-1].Refresh;
      end;

   end;
end;{TFreeEdit.BackgroundImage_Delete}

// browse for and open a backgroundimage
procedure TFreeEdit.BackgroundImage_Open(Viewport:TFreeViewport);
var I          : Integer;
    Data       : TFreebackgroundImagedata;
    Dialog     : TOpenDialog;
    Pt         : TPoint;
    P2D        : T2DCoordinate;
    Bmp        : TBitmap;
begin
   Data:=nil;
   for I:=1 to Owner.NumberofBackgroundImages do if Owner.BackgroundImage[I-1].AssignedView=Viewport.ViewType then Data:=Owner.BackgroundImage[I-1];
   if Data<>nil then
   begin
      if MessageDlg(Userstring(69)+EOL+
                    Userstring(70),mtConfirmation,[mbYes,mbNo],0)=mrNo then exit;
   end;

   Dialog:=TOpenDialog.Create(Viewport);
   Dialog.InitialDir:=Owner.Preferences.ImportDirectory;
   Dialog.Filter:='All files (*.jpg;*.bmp)|*.jpg; *.bmp|Jpeg images (*.jpg)|*.jpg|Bitmap files (*.bmp)|*.bmp|';
   Dialog.Options:=[ofHideReadOnly];
   if Dialog.Execute then
   begin
      if Data=nil then
      begin
         Data:=TFreeBackgroundImageData.Create(FOwner);
         FOwner.FBackgroundImages.Add(Data);
      end;
      Data.Clear;
      if Uppercase(ExtractFileExt(Dialog.Filename))='.JPG' then
      begin
         Data.FImageData.LoadFromFile(Dialog.FileName);
         Data.FQuality:=Data.FImageData.CompressionQuality;
      end else
      begin
         Bmp:=TBitmap.Create;
         Bmp.LoadFromFile(Dialog.Filename);
         Data.FImageData.Assign(Bmp);
         Bmp.Destroy;
         Data.FQuality:=100;
      end;
      if not Data.FImageData.Empty then
      begin
         Data.FAssignedView:=Viewport.ViewType;
         Data.FOrigin.X:=0;
         Data.FOrigin.Y:=Data.FImageData.Height;
         if Owner.NumberofBackgroundImages>1 then
         begin
            // use same scale as previous images
            Data.FScale:=Owner.BackgroundImage[Owner.NumberofBackgroundImages-2].FScale;
         end else
         begin
            // calculate scale
            Pt:=Viewport.Project(ZERO);
            Pt.X:=Viewport.ClientWidth;
            P2D:=Viewport.ProjectBackTo2D(Pt);
            Data.FScale:=P2D.X/Data.FImageData.Width;
         end;
         Data.UpdateViews;
      end;
      Owner.FileChanged:=true;
   end;
   Dialog.Destroy;

end;{TFreeEdit.BackgroundImage_Open}

constructor TFreeEdit.Create(Owner:TFreeShip);
begin
   inherited Create;
   FOwner:=Owner;
   FRecentFiles:=TStringList.Create;
end;{TFreeEdit.Create}

function TFreeEdit.CreateRedoObject:TFreeUndoObject;
var UndoObject : TFreeUndoObject;
    Version    : TFreeFileVersion;
    Preview    : Boolean;
begin
   UndoObject:=TFreeUndoObject.Create(Owner);
   Result:=UndoObject;
   UndoObject.FUndoText:=UserString(71);
   Version:=Owner.FileVersion;
   Preview:=Owner.ProjectSettings.SavePreview;
   try
      // Temp. set to the latest fileversion so that no data will be lost
      Owner.FFileVersion:=Currentversion;
      // Temp. disable saving of preview image
      Owner.ProjectSettings.SavePreview:=False;
      UndoObject.FFileChanged:=Owner.FileChanged;
      UndoObject.FFileName:=Owner.Filename;
      UndoObject.FEditMode:=Owner.EditMode;
      UndoObject.FFilenameSet:=Owner.FFilenameSet;
      UndoObject.FIsTempRedoObject:=True;
      Owner.SaveBinary(UndoObject.FUndoData);
      UndoObject.Accept;
   finally
      // Restore the original fileversion
      Owner.FileVersion:=Version;
      Owner.ProjectSettings.SavePreview:=Preview;
      if Assigned(Owner.FOnUpdateUndoData) then Owner.FOnUpdateUndoData(Owner);
   end;
end;{TFreeEdit.CreateRedoObject}

// Creates undodata just prior to modifications
function TFreeEdit.CreateUndoObject(UndoText:String;Accept:Boolean):TFreeUndoObject;
var UndoObject : TFreeUndoObject;
    Version    : TFreeFileVersion;
    Preview    : Boolean;
    I          : Integer;
begin
   UndoObject:=TFreeUndoObject.Create(Owner);
   Result:=UndoObject;
   //if UndoText<>'' then UndoText[1]:=Lowercase(UndoText[1]);
   UndoObject.FUndoText:=UndoText;
   Version:=Owner.FileVersion;
   Preview:=Owner.ProjectSettings.SavePreview;
   try
      // delete all undo objects after the current one
      for I:=FOwner.FUndoObjects.Count downto Owner.FUndoPosition+1 do
      begin
         Owner.UndoObject[I-1].Delete;
      end;
      // Temp. set to the latest fileversion so that no data will be lost
      Owner.FFileVersion:=Currentversion;
      // Temp. disable saving of preview image
      Owner.ProjectSettings.SavePreview:=False;
      UndoObject.FFileChanged:=Owner.FileChanged;
      UndoObject.FFileName:=Owner.Filename;
      UndoObject.FEditMode:=Owner.EditMode;
      UndoObject.FFilenameSet:=Owner.FFilenameSet;
      Owner.SaveBinary(UndoObject.FUndoData);
      if Accept then UndoObject.Accept;
   finally
      // Restore the original fileversion
      Owner.FileVersion:=Version;
      Owner.ProjectSettings.SavePreview:=Preview;
      if Assigned(Owner.FOnUpdateUndoData) then Owner.FOnUpdateUndoData(Owner);
   end;
end;{TFreeEdit.CreateUndoObject}

// Add (a) new controlcurve(s)
procedure TFreeEdit.Curve_Add;
var Edges      : TFasterList;
    SortedEdges: TFasterList;
    Points     : TFasterList;
    Edge       : TFreeSubdivisionControlEdge;
    I,J        : Integer;
    Point      : TFreeSubdivisionPoint;
    Curve      : TFreesubdivisionControlCurve;
begin
   Edges:=TFasterList.Create;
   Edges.Capacity:=Owner.NumberOfSelectedControlEdges;
   for I:=1 to Owner.NumberOfSelectedControlEdges do
   begin
      Edge:=Owner.SelectedControlEdge[I-1];
      if Edge.Curve=nil then Edges.Add(Edge);
   end;
   if Edges.Count>0 then
   begin
      Self.CreateUndoObject(Userstring(72),True);
      SortedEdges:=TFasterList.Create;
      Owner.Surface.IsolateEdges(Edges,SortedEdges);
      for I:=1 to SortedEdges.Count do
      begin
         Points:=SortedEdges[I-1];
         if Points.Count>1 then
         begin
            Curve:=TFreeSubdivisionControlCurve.Create(Owner.Surface);
            Owner.Surface.AddControlCurve(Curve);
            for J:=1 to Points.Count do
            begin
               Point:=Points[J-1];
               Curve.AddPoint(Point);
               if J>1 then
               begin
                  Edge:=Curve.Owner.EdgeExists(Curve.ControlPoint[J-2],Curve.ControlPoint[J-1]) as TFreeSubdivisionControlEdge;
                  if Edge<>nil then
                  begin
                     Edge.Curve:=Curve;
                  end;
               end;
            end;
         end;
         Points.Destroy;
      end;
      for I:=Owner.NumberOfSelectedControlEdges downto 1 do
      begin
         Edge:=Owner.SelectedControlEdge[I-1];
         Edge.Selected:=False;
      end;
      SortedEdges.Destroy;
      if Owner.Visibility.ShowControlCurves=false then Owner.Visibility.ShowControlCurves:=True
                                                  else Owner.Redraw;
      Owner.FileChanged:=True;
      if Assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(self);
   end;
   Edges.Destroy;
end;{TFreeEdit.Curve_Add}

destructor TFreeEdit.Destroy;
begin
   FRecentFiles.Destroy;
   Inherited Destroy;
end;{TFreeEdit.Destroy}

// Remove an edge by replacing the two connected faces by one controlface
procedure TFreeEdit.Edge_Collapse;
var I,N  : integer;
    Edge : TFreeSubdivisionControlEdge;
    Undo : TFreeUndoObject;
begin
   N:=0;
   Undo:=CreateUndoObject(Userstring(73),False);
   For I:=Owner.NumberOfSelectedControlEdges downto 1 do
   begin
      Edge:=Owner.SelectedControlEdge[I-1];
      if Edge.NumberOfFaces>1 then
      begin
         Edge.Collapse;
         inc(N);
      end;
   end;
   if N>0 then
   begin
      Undo.Accept;
      Owner.Build:=false;
      Owner.Redraw;
      Owner.FileChanged:=True;
      if Assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(self);
   end else Undo.Delete;
end;{TFreeEdit.Edge_Collapse}

// Create a new edge by connection two controlpoints belonging to the same controlface
procedure TFreeEdit.Edge_Connect;
var Undo : TFreeUndoObject;
    N    : integer;
begin
   N:=Owner.Surface.NumberOfControlEdges;
   Undo:=CreateUndoObject(Userstring(74),False);
   Owner.Surface.Edge_Connect;
   if Owner.Surface.NumberOfControlEdges>N then
   begin
      Undo.Accept;
      Owner.FileChanged:=True;
      Owner.Build:=false;
      Owner.Redraw;
      if Assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(self);
   end else Undo.Delete;
end;{TFreeEdit.Edge_Connect}

// Switch selected edges between normal or crease edges (knuckle lines)
procedure TFreeEdit.Edge_Crease;
var I    : integer;
begin
   CreateUndoObject(Userstring(75),True);
   for I:=Owner.NumberOfSelectedControlEdges downto 1 do Owner.SelectedControlEdge[I-1].Crease:=not Owner.SelectedControlEdge[I-1].Crease;
   Owner.Build:=False;
   Owner.Redraw;
   Owner.FileChanged:=True;
end;{TFreeEdit.Edge_Crease}

// Create new controlfaces by extruding selected boundary edges (eg edges with only 1 controlface connected to it)
procedure TFreeEdit.Edge_Extrude;
var Dialog  : TFreeExtrudeDialog;
    Edge    : TFreeSubdivisionControledge;
    Vector  : T3DCoordinate;
    Edges   : TFasterList;
    I       : integer;
    Str     : string;
    Undo    : TFreeUndoObject;
begin
   Dialog:=TFreeExtrudeDialog.Create(Owner);
   ShowTranslatedValues(Dialog);
   Dialog.XValue:=0.0;
   Dialog.YValue:=0.0;
   Dialog.ZValue:=0.0;
   Str:=LengthStr(Owner.ProjectSettings.ProjectUnits);
   if Dialog.Execute(Str) then
   begin
      Undo:=CreateUndoObject(Userstring(76),False);
      Vector.X:=Dialog.XValue;
      Vector.Y:=Dialog.YValue;
      Vector.Z:=Dialog.ZValue;
      // Assemble edges in a list
      Edges:=TFasterList.Create;
      for I:=Owner.NumberOfSelectedControlEdges downto 1 do
      begin
         Edge:=Owner.Surface.SelectedControlEdge[I-1];
         // only boundary edges are allowed!!
         if Edge.NumberOfFaces=1 then Edges.Add(Edge);
         Edge.Selected:=False;
      end;
      if Edges.Count>0 then
      begin
         Owner.Surface.ExtrudeEdges(Edges,Vector);
         // New edges are returned in the edges-list, select them
         for I:=1 to Edges.Count do
         begin
            Edge:=Edges[I-1];
            Edge.Selected:=True;
         end;
         Undo.Accept;
         Owner.Build:=False;
         Owner.FileChanged:=true;
         Owner.Redraw;
         if Assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(self);
      end else
      begin
         MessageDlg(Userstring(77),mtError,[mbOk],0);
         Undo.Delete;
      end;
      Edges.Destroy;
   end;
   Dialog.Destroy;
end;{TFreeEdit.Edge_Extrude}

// Create new controlpoints by splitting an controledge into two.
procedure TFreeEdit.Edge_Split;
var I,N  : integer;
    Edge : TFreeSubdivisionControlEdge;
    Point: TFreeSubdivisionControlPoint;
    Last : TFreeSubdivisionControlPoint;
    Undo : TFreeUndoObject;
begin
   N:=0;
   Last:=nil;
   Undo:=CreateUndoObject(Userstring(78),false);
   for I:=Owner.NumberOfSelectedControlEdges downto 1 do
   begin
      Edge:=Owner.Surface.SelectedControlEdge[I-1];
      Edge.Selected:=False;
      Point:=Edge.InsertControlPoint(MidPoint(Edge.StartPoint.Coordinate,Edge.EndPoint.Coordinate));
      if Point<>nil then
      begin
         Point.Selected:=True;
         Last:=Point;
         inc(N);
      end;
   end;
   if Last<>nil then Owner.ActiveControlPoint:=Last;
   if N>0 then
   begin
      Undo.Accept;
      Owner.Build:=False;
      Owner.FileChanged:=True;
      Owner.Redraw;
      if Assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(self);
   end else Undo.Delete;
end;{TFreeEdit.Edge_Split}

procedure TFreeEdit.Face_Assemble;
var Assembled        : TFreeFaceArray;
    NAssembled       : Integer;
    Layers           : TFasterList;
    I,J,K            : Integer;
    AssFace          : TFreeFaceGrid;
    Layer            : TFreeSubdivisionLayer;
    Face             : TFreeSubdivisionControlFace;
begin
   Layers:=TFasterList.Create;
   for I:=1 to Owner.Surface.NumberOfLayers do
   begin
      Layers.Add(Owner.Surface.Layer[I-1]);
   end;
   Owner.Visibility.ShowInteriorEdges:=True;
   Owner.Surface.AssembleFacesToPatches(Layers,amNurbs,Assembled,NAssembled);
   if NAssembled>0 then
   begin
      // assign all patches to new layers
      for I:=1 to NAssembled do
      begin
         Layer:=Owner.Surface.AddNewLayer;
         Layer.Color:=RandomColor;
         AssFace:=Assembled[I-1];
         for J:=1 to AssFace.NRows do
         begin
            for K:=1 to AssFace.NCols do
            begin
               Face:=AssFace.Faces[J-1][K-1];
               if Face<>nil then Face.Layer:=Layer;
            end;
         end;
      end;
      Layer_DeleteEmpty(True);
      Owner.Redraw;
      Showmessage('Assembled '+IntToStr(NAssembled)+' patches');
   end;
   Layers.Destroy;
end;{TFreeEdit.Face_Assemble}

// Deletes all faces on the starboardside of the hull
procedure TFreeEdit.Face_DeleteNegative;
var IsNegative : Boolean;
    I,J        : integer;
    RemovedF   : integer;
    RemovedP   : Integer;
    Face       : TFreeSubdivisionControlFace;
    Point      : TFreeSubdivisionControlPoint;
    PrevCursor : TCursor;
    Undo       : TFreeUndoObject;
    Str        : String;
begin
   RemovedF:=0;
   RemovedP:=0;
   PrevCursor:=Screen.Cursor;
   Screen.Cursor:=crHourglass;
   Undo:=CreateUndoObject(Userstring(79),false);
   try
      for I:=Owner.Surface.NumberOfControlFaces downto 1 do
      begin
         Face:=Owner.Surface.ControlFace[I-1];
         if face.NumberOfpoints>2 then
         begin
            IsNegative:=True;
            for J:=1 to Face.NumberOfpoints do if Face.Point[J-1].Coordinate.Y>1e-5 then IsNegative:=False;
         end else IsNegative:=True;
         if IsNegative then
         begin
            Face.Delete;
            inc(RemovedF);
         end;
      end;
      for I:=Owner.Surface.NumberOfControlPoints downto 1 do
      begin
         Point:=Owner.Surface.ControlPoint[I-1];
         if (Point.NumberOfFaces=0) and (Point.Coordinate.Y<-1e-4) then
         begin
            Point.Delete;
            inc(RemovedP);
         end;
      end;
      if (RemovedF+RemovedP)>0 then
      begin
         Str:='';
         if RemovedF>0 then Str:=Str+IntToStr(RemovedF)+#32+Userstring(80);
         if RemovedP>0 then
         begin
            if Str<>'' then Str:=Str+EOL;
            Str:=Str+IntToStr(RemovedP)+#32+Userstring(81);
         end;
         MessageDlg(Str,mtInformation,[mbOk],0);
         Undo.Accept;
         Owner.FileChanged:=True;
         Owner.Build:=False;
         Owner.Redraw;
         if Assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(self);
      end else
      begin
         MessageDlg(Userstring(82),mtInformation,[mbOk],0);
         Undo.Delete;
      end;
   finally
      Screen.Cursor:=PrevCursor;
   end;
end;{TFreeEdit.Face_DeleteNegative}

// Inverts the normal-direction of all selected controlfaces
procedure TFreeEdit.Face_Flip;
var I:integer;
begin
   CreateUndoObject(Userstring(83),true);
   for I:=1 to Owner.NumberOfSelectedControlFaces do Owner.SelectedControlFace[I-1].FlipNormal;
   Owner.Build:=False;
   Owner.FileChanged:=True;
   Owner.Redraw;
end;{TFreeEdit.Face_Flip}

// Mirrors all selected faces in a 3D plane
procedure TFreeEdit.Face_MirrorPlane;
var I,J,Index     : Integer;
    Vertices      : TFasterList;
    Points        : TFasterList;
    Faces         : TFasterList;
    MirrorPlane   : T3DPlane;
    Face,NewFace  : TFreeSubdivisionControlface;
    P1,P2         : TFreeSubdivisionControlPoint;
    Edge1,Edge2   : TFreeSubdivisionEdge;
    PrevCursor    : TCursor;
    Dialog        : TFreeMirrorPlaneDialog;
    SelectDlg     : TFreeSelectLayersDialog;
begin
   Faces:=TFasterList.Create;
   if Owner.NumberOfSelectedControlFaces=0 then
   begin
      SelectDlg:=TFreeSelectLayersDialog.Create(Owner);
      ShowTranslatedValues(SelectDlg);
      if SelectDlg.Execute(Owner,fsFaces) then SelectDlg.ExtractSelectedFaces(Faces) else
      begin
         for I:=Owner.NumberOfSelectedControlFaces downto 1 do Owner.SelectedControlFace[I-1].Selected:=false;
         Owner.Redraw;
      end;
      SelectDlg.Destroy;
   end else
   begin
      Faces.Capacity:=Faces.Count+Owner.NumberOfSelectedControlFaces;
      for I:=1 to Owner.NumberOfSelectedControlFaces do Faces.Add(Owner.SelectedControlFace[I-1]);
   end;
   if Faces.Count>0 then
   begin
      Dialog:=TFreeMirrorPlaneDialog.Create(Owner);
      ShowTranslatedValues(Dialog);
      if Dialog.Execute then
      begin
         Mirrorplane:=Dialog.Plane;

         CreateUndoObject(Userstring(84),True);
         PrevCursor:=Screen.Cursor;
         Screen.Cursor:=crHourglass;
         try
            // assemble all points
            Vertices:=TFasterlist.Create;
            Vertices.Capacity:=4*Faces.Count;
            for I:=1 to Faces.Count do
            begin
               Face:=Faces[I-1];
               for J:=1 to Face.NumberOfpoints do
               begin
                  P1:=Face.Point[J-1] as TFreeSubdivisionControlPoint;
                  if Vertices.SortedIndexOf(P1)=-1 then Vertices.AddSorted(P1);
               end;
            end;

            // Create all the mirrored control points
            for I:=1 to Vertices.Count do
            begin
               P1:=Vertices[I-1];
               if not Dialog.CheckBox1.Checked then
               begin
                  // Do NOT try to connect the points to any existing point
                  // create always a new point
                  P2:=TFreeSubdivisionControlPoint.Create(P1.Owner);
                  P1.Owner.AddControlPoint(P2);
                  P2.Coordinate:=FreeGeometry.MirrorPlane(P1.Coordinate,MirrorPlane);
               end else
               begin
                  // Try to connect ALL new points to existing ones
                  P2:=P1.Owner.AddControlPoint(FreeGeometry.MirrorPlane(P1.Coordinate,MirrorPlane));
               end;
               Vertices.Objects[I-1]:=P2;
            end;
            // now create the controlfaces
            Points:=TFasterList.Create;
            for I:=1 to Faces.Count do
            begin
               Face:=Faces[I-1];
               Points.Clear;
               Points.Capacity:=Face.NumberOfpoints;
               for J:=Face.NumberOfpoints downto 1 do
               begin
                  P1:=Face.Point[J-1] as TFreeSubdivisionControlPoint;
                  Index:=Vertices.SortedIndexOf(P1);
                  if Index<>-1 then
                  begin
                     P2:=Vertices.Objects[index];
                     Index:=Points.IndexOf(P2);
                     if Index=-1 then Points.Add(P2);
                  end else Raise Exception.Create(Userstring(85));
               end;
               if Points.Count>2 then
               begin
                  NewFace:=Face.Owner.AddControlFace(Points,False);
                  if Newface<>nil then NewFace.Layer:=Face.Layer;
               end;
            end;
            Points.Destroy;
            // Now check all edges for crease edges
            for I:=1 to Vertices.Count do
            begin
               P1:=Vertices[I-1];
               for J:=1 to P1.NumberOfEdges do
               begin
                  Edge1:=P1.Edge[J-1];
                  if Edge1.StartPoint=P1 then P2:=Edge1.EndPoint as TFreeSubdivisionControlPoint
                                         else P2:=Edge1.StartPoint as TFreeSubdivisionControlPoint;
                  Index:=Vertices.SortedIndexOf(P2);
                  if Index<>-1 then
                  begin
                     // Edge is part of the selected faces
                     Edge2:=Owner.Surface.EdgeExists(Vertices.Objects[I-1],Vertices.Objects[index]);
                     if (Edge2<>nil) and (Edge2<>Edge1) then
                     begin
                        Edge2.Crease:=Edge1.Crease;
                     end;
                  end;
               end;
            end;
            // Copy cornerpoint and locked ststus that might be lost in the edge-setting process
            for I:=1 to Vertices.Count do
            begin
               P1:=Vertices[I-1];
               P2:=Vertices.Objects[I-1];
               if P2<>P1 then
               begin
                  if P1.VertexType=svCorner then P2.VertexType:=P1.VertexType;
                  P2.Locked:=P1.Locked;
               end;
            end;
            Vertices.Destroy;
            for I:=Owner.NumberOfSelectedControlFaces downto 1 do Owner.SelectedControlFace[I-1].Selected:=False;
         finally
            Owner.Build:=False;
            Owner.Draw;
            if Assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(self);
            Screen.Cursor:=PrevCursor;
         end;
      end;
      Dialog.Destroy;
   end;
   Faces.Destroy;
end;{TFreeEdit.Face_MirrorPlane}

procedure TFreeEdit.Face_Rotate;
var I,J           : Integer;
    Nlocked       : Integer;
    Points        : TFasterList;
    PrevCursor    : TCursor;
    SelectDlg     : TFreeSelectLayersDialog;
    Point         : TFreeSubdivisionControlPoint;
    Proceed       : Boolean;
    Dialog        : TFreeRotateDialog;
    SinX,CosX     : TFloatType;
    SinY,CosY     : TFloatType;
    SinZ,CosZ     : TFloatType;
    Marker        : TFreeMarker;
begin
   Points:=TFasterList.Create;
   if Owner.ActiveControlPoint<>nil then Points.Add(Owner.ActiveControlPoint);
   Owner.Surface.ExtractPointsFromSelection(Points,NLocked);
   if Points.Count=0 then
   begin
      SelectDlg:=TFreeSelectLayersDialog.Create(Owner);
      ShowTranslatedValues(SelectDlg);
      if SelectDlg.Execute(Owner,fsPoints) then SelectDlg.ExtractSelectedPoints(Points) else
      begin
         for I:=Owner.NumberOfSelectedControlPoints downto 1 do Owner.SelectedControlPoint[I-1].Selected:=false;
         for I:=1 to Owner.NumberOfViewports do Owner.Viewport[I-1].Refresh;
      end;
      SelectDlg.Destroy;
   end;
   if Points.Count>0 then
   begin
      if NLocked>0 then
      begin
         Proceed:=MessageDlg(Userstring(86)+EOL+
                             Userstring(87),mtWarning,[mbYes,mbNo],0)=mrYes;
      end else Proceed:=True;
      if Proceed then
      begin
         Dialog:=TFreeRotateDialog.Create(Owner);
         ShowTranslatedValues(Dialog);
         Dialog.XValue:=0.0;
         Dialog.YValue:=0.0;
         Dialog.ZValue:=0.0;
         if Dialog.Execute(Userstring(88),'[Degr.]') then
         begin
            CreateUndoObject(Userstring(89),true);
            PrevCursor:=Screen.Cursor;
            Screen.Cursor:=crHourGlass;
            try
               CosX:=Cos(DegToRad(Dialog.XValue));
               SinX:=Sin(DegToRad(Dialog.XValue));
               CosY:=Cos(DegToRad(Dialog.YValue));
               SinY:=Sin(DegToRad(Dialog.YValue));
               CosZ:=Cos(DegToRad(Dialog.ZValue));
               SinZ:=Sin(DegToRad(Dialog.ZValue));

               for I:=1 to Points.Count do
               begin
                  Point:=Points[I-1];
                  if not Point.Locked then
                  begin
                     Point.Coordinate:=RotateVector(Point.Coordinate,SinX,CosX,SinY,CosY,SinZ,CosZ);
                  end;
               end;
               if Points.Count=Owner.Surface.NumberOfControlPoints then if Owner.AdjustMarkers then
               begin
                  for I:=1 to Owner.NumberofMarkers do
                  begin
                     Marker:=Owner.Marker[I-1];
                     for J:=1 to Marker.NumberOfPoints do Marker.Point[J-1]:=RotateVector(Marker.Point[J-1],SinX,CosX,SinY,CosY,SinZ,CosZ);
                  end;
               end;
               Owner.Build:=False;
               Owner.Redraw;
            finally
               // Refresh controlpoint data
               if Points.SortedIndexOf(Owner.ActiveControlPoint)<>-1 then Owner.ActiveControlPoint:=Owner.ActiveControlPoint;
               Screen.Cursor:=PrevCursor;
            end;
         end else
         begin
            for I:=Owner.NumberOfSelectedControlPoints downto 1 do Owner.SelectedControlPoint[I-1].Selected:=false;
            for I:=1 to Owner.NumberOfViewports do Owner.Viewport[I-1].Refresh;
         end;
         Dialog.Destroy;
      end else
      begin
         for I:=Owner.NumberOfSelectedControlPoints downto 1 do Owner.SelectedControlPoint[I-1].Selected:=false;
         for I:=1 to Owner.NumberOfViewports do Owner.Viewport[I-1].Refresh;
      end;
   end;
   Points.Destroy;
end;{TFreeEdit.Face_Rotate}

procedure TFreeEdit.Face_Scale;
var I             : Integer;
    Nlocked       : Integer;
    Points        : TFasterList;
    PrevCursor    : TCursor;
    SelectDlg     : TFreeSelectLayersDialog;
    Point         : TFreeSubdivisionControlPoint;
    Proceed       : Boolean;
    Dialog        : TFreeRotateDialog;
    Scale,NewP    : T3DCoordinate;
    Markers       : Boolean;
begin
   Points:=TFasterList.Create;
   if Owner.ActiveControlPoint<>nil then Points.Add(Owner.ActiveControlPoint);
   Owner.Surface.ExtractPointsFromSelection(Points,NLocked);
   if Points.Count=0 then
   begin
      SelectDlg:=TFreeSelectLayersDialog.Create(Owner);
      ShowTranslatedValues(SelectDlg);
      if SelectDlg.Execute(Owner,fsPoints) then SelectDlg.ExtractSelectedPoints(Points) else
      begin
         for I:=Owner.NumberOfSelectedControlPoints downto 1 do Owner.SelectedControlPoint[I-1].Selected:=false;
         for I:=1 to Owner.NumberOfViewports do Owner.Viewport[I-1].Refresh;
      end;
      SelectDlg.Destroy;
   end;
   if Points.Count>0 then
   begin
      if NLocked>0 then
      begin
         Proceed:=MessageDlg(Userstring(86)+EOL+
                             Userstring(87),mtWarning,[mbYes,mbNo],0)=mrYes;
      end else Proceed:=True;
      if Proceed then
      begin
         Dialog:=TFreeRotateDialog.Create(Owner);
         ShowTranslatedValues(Dialog);
         Dialog.XValue:=1.0;
         Dialog.YValue:=1.0;
         Dialog.ZValue:=1.0;

         if Dialog.Execute(Userstring(90),'') then
         begin
            CreateUndoObject(Userstring(91),true);
            PrevCursor:=Screen.Cursor;
            Screen.Cursor:=crHourGlass;
            try
               Scale.X:=Dialog.XValue;
               Scale.Y:=Dialog.YValue;
               Scale.Z:=Dialog.ZValue;
               if Points.Count=Owner.Surface.NumberOfControlPoints then
               begin
                  // Scale the entire model
                  Markers:=Owner.AdjustMarkers;
                  Model_Scale(Scale,False,Markers);
               end else
               begin
                  // only a selected part of the model must be scaled
                  for I:=1 to Points.Count do
                  begin
                     Point:=Points[I-1];
                     if not Point.Locked then
                     begin
                        NewP.X:=Scale.X*Point.Coordinate.X;
                        NewP.Y:=Scale.Y*Point.Coordinate.Y;
                        NewP.Z:=Scale.Z*Point.Coordinate.Z;
                        Point.Coordinate:=NewP;
                     end;
                  end;
                  Owner.Build:=False;
                  Owner.Redraw;
               end;
            finally
               // Refresh controlpoint data
               if Points.SortedIndexOf(Owner.ActiveControlPoint)<>-1 then Owner.ActiveControlPoint:=Owner.ActiveControlPoint;
               Screen.Cursor:=PrevCursor;
            end;
         end else
         begin
            for I:=Owner.NumberOfSelectedControlPoints downto 1 do Owner.SelectedControlPoint[I-1].Selected:=false;
            for I:=1 to Owner.NumberOfViewports do Owner.Viewport[I-1].Refresh;
         end;
         Dialog.Destroy;
      end else
      begin
         for I:=Owner.NumberOfSelectedControlPoints downto 1 do Owner.SelectedControlPoint[I-1].Selected:=false;
         for I:=1 to Owner.NumberOfViewports do Owner.Viewport[I-1].Refresh;
      end;
   end;
   Points.Destroy;
end;{TFreeEdit.Face_Scale}

procedure TFreeEdit.Face_Move;
var I,J           : Integer;
    Nlocked       : Integer;
    Points        : TFasterList;
    PrevCursor    : TCursor;
    SelectDlg     : TFreeSelectLayersDialog;
    Point         : TFreeSubdivisionControlPoint;
    Proceed       : Boolean;
    Dialog        : TFreeRotateDialog;
    P,Translate   : T3DCoordinate;
    Marker        : TFreeMarker;
begin
   Points:=TFasterList.Create;
   if Owner.ActiveControlPoint<>nil then Points.Add(Owner.ActiveControlPoint);
   Owner.Surface.ExtractPointsFromSelection(Points,NLocked);
   if Points.Count=0 then
   begin
      SelectDlg:=TFreeSelectLayersDialog.Create(Owner);
      ShowTranslatedValues(SelectDlg);
      if SelectDlg.Execute(Owner,fsPoints) then SelectDlg.ExtractSelectedPoints(Points) else
      begin
         for I:=Owner.NumberOfSelectedControlPoints downto 1 do Owner.SelectedControlPoint[I-1].Selected:=false;
         for I:=1 to Owner.NumberOfViewports do Owner.Viewport[I-1].Refresh;
      end;
      SelectDlg.Destroy;
   end;
   if Points.Count>0 then
   begin
      if NLocked>0 then
      begin
         Proceed:=MessageDlg(Userstring(86)+EOL+
                             Userstring(87),mtWarning,[mbYes,mbNo],0)=mrYes;
      end else Proceed:=True;
      if Proceed then
      begin
         Dialog:=TFreeRotateDialog.Create(Owner);
         ShowTranslatedValues(Dialog);
         Dialog.XValue:=0.0;
         Dialog.YValue:=0.0;
         Dialog.ZValue:=0.0;
         if Dialog.Execute(Userstring(92),LengthStr(Owner.ProjectSettings.ProjectUnits)) then
         begin
            CreateUndoObject(Userstring(93),true);
            Translate.X:=Dialog.XValue;
            Translate.Y:=Dialog.YValue;
            Translate.Z:=Dialog.ZValue;
            PrevCursor:=Screen.Cursor;
            Screen.Cursor:=crHourGlass;
            try
               for I:=1 to Points.Count do
               begin
                  Point:=Points[I-1];
                  if not Point.Locked then
                  begin
                     P:=Point.Coordinate;
                     P.X:=P.X+Translate.X;
                     P.Y:=P.Y+Translate.Y;
                     P.Z:=P.Z+Translate.Z;
                     Point.Coordinate:=P;
                  end;
               end;
               if Points.Count=Owner.Surface.NumberOfControlPoints then
               begin
                  // Update main dimensions
                  if not Owner.ProjectSettings.FUseDefaultMainframeLocation then Owner.ProjectSettings.ProjectMainframeLocation:=Owner.ProjectSettings.ProjectMainframeLocation+Translate.X;
                  // Update stations, buttcks and waterlines
                  for I:=1 to Owner.NumberofStations do Owner.Station[I-1].FPlane.d:=Owner.Station[I-1].FPlane.d-Translate.X;
                  for I:=1 to Owner.NumberofButtocks do Owner.Buttock[I-1].FPlane.d:=Owner.Buttock[I-1].FPlane.d-Translate.Y;
                  for I:=1 to Owner.NumberofWaterlines do Owner.Waterline[I-1].FPlane.d:=Owner.Waterline[I-1].FPlane.d-Translate.Z;
                  // Update markers
                  if Owner.AdjustMarkers then for I:=1 to Owner.NumberofMarkers do
                  begin
                     Marker:=Owner.Marker[I-1];
                     for J:=1 to Marker.NumberOfPoints do
                     begin
                        P:=Marker.Point[J-1];
                        P.X:=P.X+Translate.X;
                        P.Y:=P.Y+Translate.Y;
                        P.Z:=P.Z+Translate.Z;
                        Marker.Point[J-1]:=P;
                     end;
                  end;
               end;
               Owner.Build:=False;
               Owner.Redraw;
            finally
               // Refresh controlpoint data
               if Points.SortedIndexOf(Owner.ActiveControlPoint)<>-1 then Owner.ActiveControlPoint:=Owner.ActiveControlPoint;
               Screen.Cursor:=PrevCursor;
            end;
         end else
         begin
            for I:=Owner.NumberOfSelectedControlPoints downto 1 do Owner.SelectedControlPoint[I-1].Selected:=false;
            for I:=1 to Owner.NumberOfViewports do Owner.Viewport[I-1].Refresh;
         end;
         Dialog.Destroy;
      end else
      begin
         for I:=Owner.NumberOfSelectedControlPoints downto 1 do Owner.SelectedControlPoint[I-1].Selected:=false;
         for I:=1 to Owner.NumberOfViewports do Owner.Viewport[I-1].Refresh;
      end;
   end;
   Points.Destroy;
end;{TFreeEdit.Face_Move}

// Creates a new controlface from the currently selected controlpoints
procedure TFreeEdit.Face_New;
var Tmp     : TFasterList;
    Face    : TFreeSubdivisionControlFace;
    I       : integer;
    Undo    : TFreeUndoObject;
begin
   if Owner.NumberOfSelectedControlPoints>2 then
   begin
      Tmp:=TFasterList.Create;
      Undo:=CreateUndoObject(Userstring(94),false);
      // Remember the number of faces, edges and points
      // Assemble all points in a temp. list
      for I:=1 to Owner.Surface.NumberOfSelectedControlPoints do Tmp.Add(Owner.Surface.SelectedControlPoint[I-1]);
      // Deselect the controlpoints
      for I:=Owner.Surface.NumberOfSelectedControlPoints downto 1 do Owner.Surface.SelectedControlPoint[I-1].Selected:=False;
      // Add the new face
      Face:=Owner.Surface.AddControlFace(Tmp,True,Owner.ActiveLayer);
      if Face<>nil then
      begin
         Undo.Accept;
         Owner.Build:=False;
         Owner.FileChanged:=True;
         Owner.Redraw;
         if Assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(self);
      end else Undo.Delete;
      // Initialize then new edges and faces
      Tmp.Destroy;
   end else MessageDlg(Userstring(95),mtInformation,[mbOk],0);
end;{TFreeEdit.Face_New}

procedure TFreeEdit.File_ExportArchimedes;
var Frames     : TFasterList;
    Frame      : TFreeSpline;
    Tmp,Str    : widestring;
    I,J,Np     : integer;
    P          : T3DCoordinate;
    SaveDialog : TSaveDialog;
    ffile      : textfile;
    Strings    : TStringList;

begin  
   if not Owner.ProjectSettings.FMainparticularsHasBeenset then
   begin
      MessageDlg(Userstring(95),mtWarning,[mbOk],0);
      exit;
   end;
   Frames:=TFasterList.Create;
   Owner.FBuildValidFrameTable(Frames,True);
   if Frames.Count>0 then
   begin
      SaveDialog:=TSaveDialog.Create(Owner);
      SaveDialog.InitialDir:=Owner.Preferences.ExportDirectory;
      SaveDialog.FileName:=ChangeFileExt(ExtractFilename(Owner.FileName),'');
      SaveDialog.Filter:='ArchimedesMB multi body hull data(*.hll)|*.hll|Archimedes single body hull data(*.app)|*.app';
      SaveDialog.FilterIndex:=1;
      Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
      if SaveDialog.Execute then
      begin
         Owner.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
         if SaveDialog.FilterIndex=2 then
         begin
            // Single body Archimedes
            assignfile(ffile,ChangeFileExt(SaveDialog.FileName,'.app'));
            rewrite(FFile);
            Write(FFile,'***************************************************************'+#10);
            Write(FFile,'**                                                           **'+#10);
            Write(FFile,'**     Appendage Hydrostatics Generator                      **'+#10);
            Write(FFile,'**     Version 1.0.1                                         **'+#10);
            Write(FFile,'**     Copyright : John A. MacSween - 2000                   **'+#10);
            Write(FFile,'**     Please visit the website for updates and new versions **'+#10);
            Write(FFile,'**                                                           **'+#10);
            Write(FFile,'**                 www.naval-architecture.co.uk              **'+#10);
            Write(FFile,'** File generated with FREE!ship                             **'+#10);
            Write(FFile,'***************************************************************'+#10);
            // Hull name
            Write(FFile,'APPENDAGE_NAME'+#10);
            if Owner.ProjectSettings.ProjectName<>'' then Tmp:=Owner.ProjectSettings.ProjectName
                                                     else Tmp:=ChangeFileExt(ExtractFilename(Owner.Filename),'');
            Write(FFile,Tmp+#10);
            // Aft perpendicular
            Write(FFile,'AP'+#10);
            Write(FFile,'0.0'+#10);
            // Forward perpendicular
            Write(FFile,'FP'+#10);
            Write(FFile,Truncate(Owner.ProjectSettings.ProjectLength,4)+#10);
            // Water density
            Write(FFile,'DENSITY'+#10);
            write(FFile,Truncate(Owner.ProjectSettings.ProjectWaterDensity,3)+#10);
            // Now send the frames
            Write(FFile,'NUMBER_OF_FRAMES'+#10);
            write(FFile,IntToStr(Frames.Count)+#10);
            Write(FFile,'***START_OF_FRAME_INFORMATION***'+#10);
            for I:=1 to Frames.Count do
            begin
               Frame:=Frames[I-1];
               Np:=Frame.NumberOfPoints;
               Write(FFile,'FRAME_INDEX: '+IntToStr(I-1)+#10);
               Write(FFile,'FRAME_NAME'+#10);
               Write(FFile,'Frame @ Y= '+FloatToStrF(0.5*(Frame.Min.X+Frame.Max.X),ffFixed,7,4)+#10);
               Write(FFile,'FRAME_Y'+#10);
               Write(FFile,FloatToStrF(0.5*(Frame.Min.X+Frame.Max.X),ffFixed,7,4)+#10);
               Write(FFile,'NUMBER_OF_COORDINATES'+#10);
               write(FFile,IntToStr(2*Np-1)+#10);
               Write(FFile,'***START_OF_ORDINATES***'+#10);

               // First send the starboard side
               for J:=Np downto 1 do
               begin
                  //P:=Frame.Value((J-1)/(Np-1));
                  P:=Frame.Point[J-1];
                  P.Y:=-P.Y;
                  Write(FFile,Truncate(P.Y,4)+#10);
                  Write(FFile,Truncate(P.Z,4)+#10);
               end;
               // then port side
               for J:=2 to Np do
               begin
                  //P:=Frame.Value((J-1)/(Np-1));
                  P:=Frame.Point[J-1];
                  Write(FFile,Truncate(P.Y,4)+#10);
                  Write(FFile,Truncate(P.Z,4)+#10);
               end;
               Write(FFile,'***END_OF_ORDINATES***'+#10);
               Frame.Destroy;
            end;
            Write(FFile,'***END_OF_FILE***'+#10);
            closefile(FFile);
         end else
         begin
            // Multi body ArchimedesMB
            Strings:=TStringList.Create;
            // Add file version info
            Strings.Add(' <?xml version="1.0" encoding="UTF-8" ?>');
            // Start hull
            Strings.Add('<HULL>');
            // Hull name
            Strings.Add('<HULL_NAME>');
            if Owner.ProjectSettings.ProjectName<>'' then Str:=Owner.ProjectSettings.ProjectName
                                                     else Str:=ChangeFileExt(ExtractFilename(Owner.Filename),'');
            Strings.Add(Str);
            Strings.Add('</HULL_NAME>');
            // Water density
            Strings.Add('<DENSITY>'+#32+Truncate(Owner.ProjectSettings.ProjectWaterDensity,3)+#32+'</DENSITY>');
            // Aft perpendicular
            Strings.Add('<AP> 0.0 </AP>');
            // Forward perpendicular
            Strings.Add('<FP>'+#32+Truncate(Owner.ProjectSettings.ProjectLength,4)+#32+'</FP>');
            // Draught marks
            Strings.Add('<FWD_DRAUGHT_MARK>'+#32+Truncate(Owner.ProjectSettings.ProjectDraft,4)+#32+'</FWD_DRAUGHT_MARK>');
            Strings.Add('<MID_DRAUGHT_MARK>'+#32+Truncate(Owner.ProjectSettings.ProjectDraft,4)+#32+'</MID_DRAUGHT_MARK>');
            Strings.Add('<AFT_DRAUGHT_MARK>'+#32+Truncate(Owner.ProjectSettings.ProjectDraft,4)+#32+'</AFT_DRAUGHT_MARK>');
            // Number of appendages (only 1, the main hull)
            Strings.Add('<APPENDAGE_COUNT> 1 </APPENDAGE_COUNT>');
            Strings.Add('<APPENDAGE>');
            Strings.Add('<APPENDAGE_NAME>');
            Strings.Add('Main Hull');
            Strings.Add('</APPENDAGE_NAME>');
            // Some constants
            Strings.Add('<ACTIVE> 1 </ACTIVE>');
            Strings.Add('<FREE_FLOODING> 0 </FREE_FLOODING>');
            Strings.Add('<APPENDAGE_COLOUR> 0 </APPENDAGE_COLOUR>');

            // Now send the frames
            Strings.Add('<SECTION_COUNT>'+#32+IntToStr(Frames.Count)+#32+'</SECTION_COUNT>');
            for I:=1 to Frames.Count do
            begin
               Frame:=Frames[I-1];
               Np:=2*Frame.NumberOfPoints+1;
               Strings.Add('<SECTION>');
               Strings.Add('<SECTION_NAME>');
               Strings.Add(FloatToStrF(0.5*(Frame.Min.X+Frame.Max.X),ffFixed,7,4));
               Strings.Add('</SECTION_NAME>');
               Strings.Add('<YCOORD>'+#32+FloatToStrF(0.5*(Frame.Min.X+Frame.Max.X),ffFixed,7,4)+#32+'</YCOORD>');
               Strings.Add('<OFFSET_COUNT>'+#32+IntToStr(2*Np-1)+#32+'</OFFSET_COUNT>');
               Strings.Add('<OFFSETS>');
               // First send the starboard side
               for J:=Np downto 1 do
               begin
                  P:=Frame.Value((J-1)/(Np-1));
                  P.Y:=-P.Y;
                  Strings.Add(Truncate(P.Y,4)+#32+Truncate(P.Z,4));
               end;
               // then port side
               for J:=2 to Np do
               begin
                  P:=Frame.Value((J-1)/(Np-1));
                  Strings.Add(Truncate(P.Y,4)+#32+Truncate(P.Z,4));
               end;
               Strings.Add('</OFFSETS>');
               Strings.Add('</SECTION>');
               Frame.Destroy;
            end;
            Strings.Add('</APPENDAGE>');  // end of appendage
            Strings.Add('</HULL>');       // end of hull
            Strings.SaveToFile(ChangeFileExt(SaveDialog.FileName,'.hll'));
            Strings.Destroy;
         end;
      end else
      begin
         for I:=1 to Frames.Count do
         begin
            Frame:=Frames[I-1];
            Frame.Destroy;
         end;
      end;
      SaveDialog.Destroy;
   end;
   Frames.Destroy;
end;{TFreeEdit.File_ExportArchimedes}

// export the coordinates of all controlpoints to a textfile
procedure TFreeEdit.File_ExportCoordinates;
var I          : integer;
    Point      : TFreeSubdivisionPoint;
    SaveDialog : TSaveDialog;
    ffile      : textfile;
begin
   SaveDialog:=TSaveDialog.Create(Owner);
   SaveDialog.InitialDir:=Owner.Preferences.ExportDirectory;
   SaveDialog.FileName:=ChangeFileExt(ExtractFilename(Owner.FileName),'');
   SaveDialog.Filter:='Text file(*.txt)|*.txt';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then
   begin
      Assignfile(FFile,ChangeFileExt(SaveDialog.FileName,'.txt'));
      {$I-}Rewrite(FFile);{$I+}
      if IOResult=0 then
      begin
         Owner.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
         {
         for I:=1 to Owner.Surface.NumberOfControlPoints do
         begin
            Point:=Owner.Surface.ControlPoint[I-1];
            Writeln(FFile,MakeLength(Point.Coordinate.X,6,12),#32,
                          MakeLength(Point.Coordinate.Y,6,12),#32,
                          MakeLength(Point.Coordinate.Z,6,12));
         end;
         }
         for I:=1 to Owner.Surface.NumberOfPoints do
         begin
            Point:=Owner.Surface.Point[I-1];
            Writeln(FFile,MakeLength(Point.Coordinate.X,6,12),#32,
                          MakeLength(Point.Coordinate.Y,6,12),#32,
                          MakeLength(Point.Coordinate.Z,6,12));
         end;
         CloseFile(FFile);
      end else
      begin
         MessageDlg(Userstring(97),mtError,[mbOk],0);
      end;
   end;
   SaveDialog.Destroy;

end;{TFreeEdit.File_ExportCoordinates}

// Export all intersections to an individual DXF file as 2D polylines
procedure TFreeEdit.File_ExportDXF_2DPolylines;
var I          : integer;
    Strings    : TStringList;
    Dialog     : TDXFExport2DDialog;
    ScaleFactor: Double;
    SegLength  : double;
    PrevCursor : TCursor;
    Filename   : string;
    Intersections:TFasterList;

    procedure CreateDXFData(Intersection:TFreeIntersection;Stringlist:TStringList;Scale:Double;var Filename:string);
    var I,N    :Integer;
        Layername:string;

         procedure SaveSpline(Spline:TFreeSpline;Strings:TStringList;IntersectionType:TFreeIntersectiontype);
         var NParams : Integer;
             Cap     : Integer;
             Params  : TFloatArray;
             I,Ind   : Integer;
             Length  : Double;
             T       : Double;
             P1,P2   : T3DCoordinate;

         begin
            Ind:=FindDXFColorIndex(Spline.Color);
            NParams:=0;
            Setlength(Params,Spline.NumberOfPoints);
            // count number of knucklepoints
            if not Spline.Build then Spline.Rebuild;
            for I:=2 to Spline.NumberOfPoints-1 do
            begin
               if Spline.Knuckle[I-1] then
               begin
                  Params[NParams]:=Spline.Parameter[I-1];
                  inc(NParams);
               end;
            end;
            // Calculate the length of the spline
            Length:=0.0;
            P1:=Spline.Value(0.0);
            for I:=1 to 150 do
            begin
               P2:=Spline.Value(I/150);
               Length:=Length+DistPP3D(P1,P2);
               P1:=P2;
            end;
            Length:=Length*ScaleFactor;


            if length>0 then
            begin
               N:=Round(Length/(SegLength));
               if N<2*Spline.NumberOfPoints then N:=2*Spline.NumberOfPoints;
               if N>3500 then N:=3500;
               Spline.Fragments:=N;
               Cap:=NParams+100;
               Setlength(Params,Cap);
               inc(Nparams);
               Params[NParams-1]:=0.0;
               inc(Nparams);
               Params[NParams-1]:=1.0;

               for I:=1 to Spline.Fragments do
               begin
                  T:=Spline.ChordlengthApproximation(I*SegLength/Length);
                  if NParams>=Cap then
                  begin
                     inc(Cap,50);
                     Setlength(Params,Cap);
                  end;
                  inc(NParams);
                  Params[NParams-1]:=T;
               end;

               SortFloatArray(Params,NParams);
               // now export the actual calculated points
               Strings.Add('0'+EOL+'POLYLINE');
               Strings.Add('8'+EOL+LayerName);   // layername
               Strings.Add('62'+EOL+IntToStr(Ind));  // color by layer
               Strings.Add('66'+EOL+'1');    // vertices follow
               for I:=1 to NParams do
               begin
                  P1:=Spline.Value(Params[I-1]);
                  Strings.Add('0'+EOL+'VERTEX');
                  Strings.Add('8'+EOL+LayerName);

                  Case IntersectionType of
                     fiStation    : begin
                                       Strings.Add('10'+EOL+Truncate(Scale*P1.Y,5));
                                       Strings.Add('20'+EOL+Truncate(Scale*P1.Z,5));
                                    end;
                     fiButtock    : begin
                                       Strings.Add('10'+EOL+Truncate(Scale*P1.X,5));
                                       Strings.Add('20'+EOL+Truncate(Scale*P1.Z,5));
                                    end;
                     fiWaterline  : begin
                                       Strings.Add('10'+EOL+Truncate(Scale*P1.X,5));
                                       Strings.Add('20'+EOL+Truncate(Scale*P1.Y,5));
                                    end;
                  end;
               end;
               Strings.Add('0'+EOL+'SEQEND');
               if (Intersectiontype in [fiStation,fiWaterline]) and (Owner.Visibility.ModelView=mvBoth) then
               begin
                  // send the other half
                  Strings.Add('0'+EOL+'POLYLINE');
                  Strings.Add('8'+EOL+LayerName);   // layername
                  Strings.Add('62'+EOL+IntToStr(Ind));  // color by layer
                  Strings.Add('66'+EOL+'1');    // vertices follow
                  for I:=1 to NParams do
                  begin
                     P1:=Spline.Value(Params[I-1]);
                     Strings.Add('0'+EOL+'VERTEX');
                     Strings.Add('8'+EOL+LayerName);
                     Case IntersectionType of
                        fiStation    : begin
                                          Strings.Add('10'+EOL+Truncate(Scale*-P1.Y,5));
                                          Strings.Add('20'+EOL+Truncate(Scale*P1.Z,5));
                                       end;
                        fiWaterline  : begin
                                          Strings.Add('10'+EOL+Truncate(Scale*P1.X,5));
                                          Strings.Add('20'+EOL+Truncate(Scale*-P1.Y,5));
                                       end;
                     end;
                  end;
                  Strings.Add('0'+EOL+'SEQEND');
               end;
            end;
         end;{SaveSpline}

    begin
       if not Intersection.Build then Intersection.Rebuild;
       if intersection.Count>0 then
       begin
         Case Intersection.IntersectionType of
            fiStation  :begin
                           Layername:=Userstring(62);
                        end;
            fiButtock  :begin
                           Layername:=Userstring(63);
                        end;
            fiWaterline:begin
                           Layername:=Userstring(64);
                        end;
            fiDiagonal :begin
                           Layername:=Userstring(65);
                        end;
            else
            begin
               Messagedlg(Userstring(66)+'!',mtError,[mbOk],0);
               exit;
            end;
         end;
         Filename:=Owner.Preferences.ExportDirectory+Intersection.Description+'.dxf';
         for I:=1 to Intersection.Count do
         begin
            Intersection.Items[I-1].Color:=Intersection.Color;
            SaveSpline(Intersection.Items[I-1],Strings,Intersection.IntersectionType);
         end;
       end;
    end;

begin
   Dialog:=TDXFExport2DDialog.Create(Owner);
   ShowTranslatedValues(Dialog);
   Dialog.ExportDirectory:=Owner.Preferences.ExportDirectory;
   If Owner.ProjectSettings.ProjectUnits=fuMetric then Dialog.ComboBox1.ItemIndex:=0 else
      If Owner.ProjectSettings.ProjectUnits=fuImperial then Dialog.ComboBox1.ItemIndex:=3;

   if Dialog.Execute then
   begin
      Owner.Preferences.ExportDirectory:=Dialog.ExportDirectory;
      if Length(Owner.Preferences.ExportDirectory)>0 then if Owner.Preferences.ExportDirectory[Length(Owner.Preferences.ExportDirectory)]<>'\' then
      begin
         Owner.Preferences.ExportDirectory:=Owner.Preferences.ExportDirectory+'\';
      end;

      ScaleFactor:=1.0;
      SegLength:=Dialog.SegmentLength;
      If Owner.ProjectSettings.ProjectUnits=fuMetric then
      begin
         Case Dialog.ComboBox1.ItemIndex of
            0 : ScaleFactor:=1.0;         // Scale from meters to meters
            1 : ScaleFactor:=100;         // Scale from meters to centimeters
            2 : ScaleFactor:=1000;        // Scale from meters to millimeters
            3 : ScaleFactor:=1/Foot;      // Scale from meters to feet
            4 : ScaleFactor:=12/Foot;     // Scale from meters to inches
         end;
      end else If Owner.ProjectSettings.ProjectUnits=fuImperial then
      begin
         Case Dialog.ComboBox1.ItemIndex of
            0 : ScaleFactor:=Foot;        // Scale from feet to meters
            1 : ScaleFactor:=100*foot;    // Scale from feet to centimeters
            2 : ScaleFactor:=1000*foot;   // Scale from feet to millimeters
            3 : ScaleFactor:=1.0;         // Scale from feet to feet
            4 : ScaleFactor:=12;          // Scale from feet to inches
         end;
      end;

      Strings:=TStringList.Create;
      PrevCursor:=Screen.Cursor;
      Screen.Cursor:=crHourGlass;
      try
         if Dialog.CheckBox1.Checked then
         begin
            // send each intersection to an individual dxf file
            Intersections:=TFasterList.Create;
            if Owner.Visibility.ShowStations then Intersections.AddList(Owner.FStations);
            if Owner.Visibility.ShowButtocks then Intersections.AddList(Owner.FButtocks);
            if Owner.Visibility.ShowWaterlines then Intersections.AddList(Owner.FWaterlines);
            for I:=1 to Intersections.Count do
            begin
               Strings.Clear;
               Strings.Add('0'+EOL+'SECTION');
               Strings.Add('2'+EOL+'ENTITIES');
               CreateDXFData(Intersections[I-1],Strings,ScaleFactor,Filename);
               Strings.Add('0'+EOL+'ENDSEC');
               Strings.Add('0'+EOL+'EOF');
               Strings.SaveToFile(Filename);
            end;
            Intersections.Destroy;
         end else
         begin
            if (Owner.Visibility.ShowStations) and (Owner.NumberofStations>0) then
            begin
               Strings.Clear;
               Strings.Add('0'+EOL+'SECTION');
               Strings.Add('2'+EOL+'ENTITIES');
               for I:=1 to Owner.NumberofStations do CreateDXFData(Owner.Station[I-1],Strings,ScaleFactor,Filename);
               Strings.Add('0'+EOL+'ENDSEC');
               Strings.Add('0'+EOL+'EOF');
               Filename:=Owner.Preferences.ExportDirectory+'stations.dxf';
               Strings.SaveToFile(Filename);
            end;
            if (Owner.Visibility.ShowButtocks) and (Owner.NumberofButtocks>0) then
            begin
               Strings.Clear;
               Strings.Add('0'+EOL+'SECTION');
               Strings.Add('2'+EOL+'ENTITIES');
               for I:=1 to Owner.NumberofButtocks do CreateDXFData(Owner.Buttock[I-1],Strings,ScaleFactor,Filename);
               Strings.Add('0'+EOL+'ENDSEC');
               Strings.Add('0'+EOL+'EOF');
               Filename:=Owner.Preferences.ExportDirectory+'buttocks.dxf';
               Strings.SaveToFile(Filename);
            end;
            if (Owner.Visibility.ShowWaterlines) and (Owner.NumberofWaterlines>0) then
            begin
               Strings.Clear;
               Strings.Add('0'+EOL+'SECTION');
               Strings.Add('2'+EOL+'ENTITIES');
               for I:=1 to Owner.NumberofWaterlines do CreateDXFData(Owner.Waterline[I-1],Strings,ScaleFactor,Filename);
               Strings.Add('0'+EOL+'ENDSEC');
               Strings.Add('0'+EOL+'EOF');
               Filename:=Owner.Preferences.ExportDirectory+'waterlines.dxf';
               Strings.SaveToFile(Filename);
            end;
         end;
      finally
         Strings.Destroy;
         Screen.Cursor:=PrevCursor;
      end;
   end;
   Dialog.Destroy;
end;{TFreeEdit.File_ExportDXF_2DPolylines}

// Export all lines to a 3D DXF model as polylines
procedure TFreeEdit.File_ExportDXF_3DPolylines;
var I,J,ind : integer;
    Strings : TStringList;
    Dialog  : TSaveDialog;
    Edges   : TFasterList;
    Points  : TFasterList;
    Point   : TFreeSubdivisionPoint;
    Layername:string;
begin
   Dialog:=TSaveDialog.Create(Owner);
   Dialog.InitialDir:=Owner.Preferences.ExportDirectory;
   Dialog.FileName:=ChangeFileExt(ExtractFilename(Owner.FileName),'.dxf');
   Dialog.Filter:='Autocad dxf file (*.dxf)|*.dxf';
   dialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if Dialog.Execute then
   begin
      Owner.Preferences.ExportDirectory:=ExtractFilePath(Dialog.FileName);
      Strings:=TStringList.Create;
      Strings.Add('0'+EOL+'SECTION');
      Strings.Add('2'+EOL+'ENTITIES');
      if Owner.Visibility.ShowStations then for I:=1 to Owner.NumberofStations do Owner.Station[I-1].SaveToDXF(Strings);
      if Owner.Visibility.ShowButtocks then for I:=1 to Owner.NumberofButtocks do Owner.Buttock[I-1].SaveToDXF(Strings);
      if Owner.Visibility.ShowWaterlines then for I:=1 to Owner.NumberofWaterlines do Owner.Waterline[I-1].SaveToDXF(Strings);
      if Owner.Visibility.ShowDiagonals then for I:=1 to Owner.NumberofDiagonals do Owner.Diagonal[I-1].SaveToDXF(Strings);
      if Owner.Visibility.ShowControlCurves then for I:=1 to Owner.NumberofControlCurves do Owner.ControlCurve[I-1].SaveToDXF(Strings);

      Edges:=TFasterList.Create;
      Owner.Surface.ExtractAllEdgeLoops(Edges);
      Layername:='Edges';
      ind:=FindDXFColorIndex(Owner.Preferences.EdgeColor);
      for I:=1 to Edges.Count do
      begin
         Points:=Edges[I-1];
         Strings.Add('0'+EOL+'POLYLINE');
         Strings.Add('8'+EOL+LayerName);   // layername
         Strings.Add('62'+EOL+IntToStr(Ind));  // color by layer
         Strings.Add('70'+EOL+'10');   // not closed
         Strings.Add('66'+EOL+'1');    // vertices follow
         for J:=1 to Points.Count do
         begin
            Point:=Points[J-1];
            Strings.Add('0'+EOL+'VERTEX');
            Strings.Add('8'+EOL+LayerName);
            Strings.Add('10'+EOL+Truncate(Point.Coordinate.X,4));
            Strings.Add('20'+EOL+Truncate(Point.Coordinate.Y,4));
            Strings.Add('30'+EOL+Truncate(Point.Coordinate.Z,4));
            Strings.Add('70'+EOL+'32');    // 3D polyline mesh vertex
         end;
         Strings.Add('0'+EOL+'SEQEND');
         if Owner.Visibility.ModelView=mvBoth then
         begin
            Strings.Add('0'+EOL+'POLYLINE');
            Strings.Add('8'+EOL+LayerName);   // layername
            Strings.Add('62'+EOL+IntToStr(Ind));  // color by layer
            Strings.Add('70'+EOL+'10');   // not closed
            Strings.Add('66'+EOL+'1');    // vertices follow
            for J:=1 to Points.Count do
            begin
               Point:=Points[J-1];
               Strings.Add('0'+EOL+'VERTEX');
               Strings.Add('8'+EOL+LayerName);
               Strings.Add('10'+EOL+Truncate(Point.Coordinate.X,4));
               Strings.Add('20'+EOL+Truncate(-Point.Coordinate.Y,4));
               Strings.Add('30'+EOL+Truncate(Point.Coordinate.Z,4));
               Strings.Add('70'+EOL+'32');    // 3D polyline mesh vertex
            end;
            Strings.Add('0'+EOL+'SEQEND');
         end;
         Points.Destroy;
      end;
      Edges.Destroy;
      Strings.Add('0'+EOL+'ENDSEC');
      Strings.Add('0'+EOL+'EOF');
      Strings.SaveToFile(ChangeFileExt(Dialog.FileName,'.dxf'));
      Strings.Destroy;
   end;
   Dialog.Destroy;
end;{TFreeEdit.File_ExportDXF_3DPolylines}

// Export all faces to a 3D DXF model
procedure TFreeEdit.File_ExportDXF_Faces;
var I       : integer;
    Strings : TStringList;
    Dialog  : TSaveDialog;
    Prev    : TCursor;
begin
   Dialog:=TSaveDialog.Create(Owner);
   Dialog.InitialDir:=Owner.Preferences.ExportDirectory;
   Dialog.FileName:=ChangeFileExt(ExtractFilename(Owner.FileName),'.dxf');
   Dialog.Filter:='Autocad dxf file (*.dxf)|*.dxf';
   dialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if Dialog.Execute then
   begin
      Prev:=Screen.Cursor;
      Screen.Cursor:=crHourglass;
      try
         Owner.Preferences.ExportDirectory:=ExtractFilePath(Dialog.FileName);
         Strings:=TStringList.Create;
         Strings.Add('0'+EOL+'SECTION');
         Strings.Add('2'+EOL+'ENTITIES');
         for I:=1 to Owner.Surface.NumberOfLayers do Owner.Surface.Layer[I-1].SaveToDXF(Strings);
         Strings.Add('0'+EOL+'ENDSEC');
         Strings.Add('0'+EOL+'EOF');
         try
            Strings.SaveToFile(ChangeFileExt(Dialog.FileName,'.dxf'));
         except
            MessageDlg('Could not access '+ChangeFileExt(Dialog.FileName,'.dxf'),mtError,[mbOk],0);
         end;
      finally
         Screen.Cursor:=Prev;
      end;
      Strings.Destroy;
   end;
   Dialog.Destroy;
end;{TFreeEdit.File_ExportDXF_Faces}

procedure TFreeEdit.File_ExportFEF;
var SaveDialog : TSaveDialog;
    Strings    : TStringlist;
begin
   SaveDialog:=TSaveDialog.Create(Owner);
   SaveDialog.InitialDir:=Owner.Preferences.ExportDirectory;
   SaveDialog.FileName:=ChangeFileExt(ExtractFilename(Owner.FileName),'.fef');
   SaveDialog.Filter:='FREE!ship Exchange Format (*.Fef)|*.fef';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then
   begin
      Owner.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
      Strings:=TStringlist.Create;
      // Add general info and mainparticulars
      Strings.Add(Owner.ProjectSettings.ProjectName);
      Strings.Add(Owner.ProjectSettings.ProjectDesigner);
      Strings.Add(Owner.ProjectSettings.ProjectFileCreatedBy);
      Strings.Add(Owner.ProjectSettings.ProjectComment);
      Strings.Add(Truncate(Owner.ProjectSettings.ProjectLength,4)+#32+Truncate(Owner.ProjectSettings.ProjectBeam,4)+#32+
                  Truncate(Owner.ProjectSettings.ProjectDraft,4)+#32+Truncate(Owner.ProjectSettings.ProjectWaterDensity,5)+#32+
                  Truncate(Owner.ProjectSettings.ProjectAppendageCoefficient,5)+#32+IntToStr(Ord(Owner.ProjectSettings.ProjectUnits))+#32+
                  BoolToStr(Owner.ProjectSettings.MainparticularsHasBeenset)+#32+IntToStr(Ord(Owner.Precision)));
      Owner.Surface.ExportFeFFile(Strings);
      Strings.SaveToFile(ChangeFileExt(Savedialog.FileName,'.fef'));
      Strings.Destroy;
   end;
   SaveDialog.Destroy;
end;{TFreeEdit.File_ExportFEF}

// Save ordinates to the GHS file format
procedure TFreeEdit.File_ExportGHS;
var I,J        : integer;
    Section    : TFreeSpline;
    SaveDialog : TSaveDialog;
    Strings    : TStringList;
    PrevCursor : TCursor;
    Scale      : TFloatType;
    Frames     : TFasterList;
    Str        : string;
    P          : T3DCoordinate;
    NParams    : Integer;
    Params     : TFloatArray;
begin
   if not owner.ProjectSettings.FMainparticularsHasBeenset then
   begin
      MessageDlg(Userstring(95),mtWarning,[mbOk],0);
      exit;
   end;
   SaveDialog:=TSaveDialog.Create(owner);
   SaveDialog.InitialDir:=Owner.Preferences.ExportDirectory;
   Str:=ChangeFileExt(ExtractFilename(Owner.Filename),'.GF');
   // no spaces allowed in filename
   repeat
      I:=Pos(#32,Str);
      if I<>0 then Delete(Str,I,1);
   until I=0;
   Savedialog.FileName:=Str;
   SaveDialog.Filter:='GHS files (*.Gf)|*.Gf';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if not SaveDialog.Execute then
   begin
      Savedialog.Destroy;
      exit;
   end;
   Owner.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
   PrevCursor:=Screen.Cursor;
   Screen.Cursor:=crHourGlass;
   Strings:=TStringList.Create;
   Frames:=TFasterList.Create;
   try
      Owner.FBuildValidFrameTable(Frames,True);
      if Owner.ProjectSettings.ProjectUnits=fuImperial then Scale:=1.0
                                                       else Scale:=1/Foot;
      Str:=Owner.ProjectSettings.ProjectName;
      if Length(Str)>58 then Str:=copy(Str,1,58);
      Strings.Add(Str);                                                                      // ProjectDescription, max 58 characters
      Strings.Add('L:'+FloatToStrF(Scale*Owner.ProjectSettings.ProjectLength,ffFixed,7,3));  // Length
      Strings.Add('W:'+FloatToStrF(Scale*Owner.ProjectSettings.ProjectBeam,ffFixed,7,3));    // Beam
      Strings.Add('OL:Frame 0');
      Strings.Add('OT:Centerplane');
      Strings.Add('OV:Baseline');
      // Units preference
      if Owner.ProjectSettings.ProjectUnits=fuMetric then Strings.Add('P:M')
                                                     else Strings.Add('P:F');
      // Add max. 10 comments
      Strings.Add('\Generated with FREE!ship');
      Strings.Add('\www.freeship.org');

      // Save shape
      Strings.Add('*');
      Strings.Add('HULL'); // shape name
      Strings.Add(IntToStr(Frames.Count)); // Number of sections
      for I:=Frames.Count downto 1 do
      begin
         Section:=Frames[I-1];
         if Section.NumberOfPoints>0 then
         begin
            if section.Point[Section.NumberOfPoints-1].Y>0 then
            begin
               Section.Knuckle[Section.NumberOfPoints-1]:=true;
               Section.Add(Section.Point[Section.NumberOfPoints-1]);
            end;
         end;

         NParams:=0;
         Setlength(Params,Section.NumberOfPoints);
         // count number of knucklepoints
         for J:=2 to Section.NumberOfPoints-1 do
         begin
            if Section.Knuckle[J-1] then
            begin
               Params[NParams]:=Section.Parameter[J-1];
               inc(NParams);
            end;
         end;
         if Section.NumberOfPoints>100 then
         begin
            Section.Fragments:=100;
            Setlength(Params,NParams+Section.Fragments);
            for J:=1 to Section.Fragments do
            begin
               Params[NParams]:=(J-1)/(Section.Fragments-1);
               inc(NParams);
            end;
         end else
         begin
            Setlength(Params,NParams+Section.NumberOfPoints);
            for J:=1 to Section.NumberOfPoints do
            begin
               Params[NParams]:=Section.Parameter[J-1];
               inc(NParams);
            end;
         end;
         SortFloatArray(Params,NParams);
         Strings.Add(Truncate(-Scale*Section.Min.X,4)+','+IntToStr(NParams));
         for J:=1 to NParams do
         begin
            P:=Section.Value(Params[J-1]);
            Strings.Add(Truncate(Scale*P.Y,4)+','+Truncate(Scale*P.Z,4));
         end;
         Section.Destroy;
      end;
      Strings.Add('0,0,0');         // shell thickness data of shape


      // save Component
      Strings.Add('**');
      Strings.Add('HULL.C');        // ComponentName
      // side
      Strings.Add('0');             // side=center
      Strings.Add('1.0');           // effectivenes
      Strings.Add('0,0,0');         // attachpoint
      Strings.Add('HULL');          // partname

      // Save part
      Strings.Add('***');
      Strings.Add('HULL');          // Partname and description
      Strings.Add('WATER');                  // FluidName
      strings.Add('1');                      // part type (displacement)
      if Owner.ProjectSettings.ProjectUnits=fuMetric then Strings.Add(FloatToStrF(Owner.ProjectSettings.ProjectWaterDensity,ffFixed,7,3)) // specific gravity of water
                                                     else Strings.Add(FloatToStrF(Owner.ProjectSettings.ProjectWaterDensity/WeightConversionFactor,ffFixed,7,3));
      Strings.Add('0,0,0');      // ReferencePoint
      Strings.Add('1');          // Number of components
      Strings.Add('HULL.C');     // Componentname
      // Mark end of file
      Strings.Add('****');
      Str:=ChangeFileExt(ExtractFilename(Savedialog.FileName),'.GF');
      // no spaces allowed in filename
      repeat
         I:=Pos(#32,Str);
         if I<>0 then Delete(Str,I,1);
      until I=0;
      Str:=ExtractFilePath(SaveDialog.Filename)+Str;
      Strings.SaveToFile(Str);

      SaveDialog.Destroy;
   finally
      Frames.Destroy;
      Screen.Cursor:=PrevCursor;
      Strings.Destroy;
   end;
end;{TFreeEdit.File_ExportGHS}

// Save part of the geometry to a file
procedure TFreeEdit.File_ExportPart;
var SelectDlg  : TFreeSelectLayersDialog;
    Faces      : TFasterList;
    I          : Integer;
begin
   Faces:=TFasterList.Create;
   if Owner.NumberOfSelectedControlFaces=0 then
   begin
      SelectDlg:=TFreeSelectLayersDialog.Create(Owner);
      ShowTranslatedValues(SelectDlg);
      if SelectDlg.Execute(Owner,fsFaces) then SelectDlg.ExtractSelectedFaces(Faces);
      for I:=Owner.NumberOfSelectedControlFaces downto 1 do Owner.SelectedControlFace[I-1].Selected:=false;
      Owner.Redraw;
      SelectDlg.Destroy;
   end else
   begin
      Faces.Capacity:=Faces.Count+Owner.NumberOfSelectedControlFaces;
      for I:=1 to Owner.NumberOfSelectedControlFaces do Faces.Add(Owner.SelectedControlFace[I-1]);
   end;
   if Faces.Count>0 then Owner.SavePart(Faces);
   Faces.Destroy;
end;{TFreeEdit.File_ExportPart}

// Save NURBS patches to an IGES file
procedure TFreeEdit.File_ExportIGES;
const MinimizeFaces  = True;
      SendTriangles  = False;//true;
var I,J,K         : integer;
    Cols,Rows     : Integer;
    Dialog        : TSaveDialog;
    Prev          : TCursor;
    Layers        : TFasterList;
    Layer         : TFreeSubdivisionLayer;
    FaceData      : TFreeFaceGrid;
    Assembled     : TFreeFaceArray;
    NAssembled    : Integer;
    IGESList      : TFreeIGESList;
    Grid          : TFreeSubdivisionGrid;
    CtrlFace      : TFreeSubdivisionControlFace;
    Face          : TFreeSubdivisionFace;
    PrevLevel     : Integer;
    ColorIndices  : array of Integer;
    ColorIndex    : Integer;
    NSurfaces     : Integer;
    CheckFaces    : TFasterlist;


    function FindFourtPoint(P1,P2,p3:TFreeSubdivisionPoint):TFreeSubdivisionPoint;
    var Face  : TFreeSubdivisionFace;
        I,J   : Integer;
        List  : TList;
    begin
       Result:=nil;
       if (P1<>P2) and (P2<>P3) and (P1<>P3) then
       begin
          for I:=1 to P2.NumberOfFaces do
          begin
             Face:=P2.Face[I-1];
             if (Face.IndexOfPoint(P1)<>-1) and
               // (Face.IndexOfPoint(P2)<>-1) and
                (Face.IndexOfPoint(P3)<>-1) then
             begin
                List:=TList.Create;
                for J:=1 to face.NumberOfpoints do list.Add(Face.Point[J-1]);
                J:=List.IndexOf(P1);
                if J<>-1 then list.Delete(J);
                J:=List.IndexOf(P2);
                if J<>-1 then list.Delete(J);
                J:=List.IndexOf(P3);
                if J<>-1 then list.Delete(J);
                if list.Count>0 then result:=List[0];
                List.Destroy;
             end;
          end;
       end;
    end;{FindFourtPoint}

    procedure FindOpposingPoints(P1,P2,P3,P4:TFreeSubdivisionPoint;var OppPoint2,OppPoint3:TFreeSubdivisionPoint);
    // find the points opposite to P2 and P3
    var I,Index:Integer;
        Edge:TFreeSubdivisionEdge;
        Face:TFreeSubdivisionface;
    begin
       OppPoint2:=nil;
       OppPoint3:=nil;
       Edge:=Owner.Surface.EdgeExists(P2,P3);
       if Edge<>nil then if not Edge.Crease then
       begin
          for I:=1 to Edge.NumberOfFaces do
          begin
             Face:=Edge.Face[I-1];
             if (Face.IndexOfPoint(P1)=-1) or
                (Face.IndexOfPoint(P2)=-1) or
                (Face.IndexOfPoint(P3)=-1) or
                (Face.IndexOfPoint(P4)=-1) then
             begin
                Index:=Face.IndexOfPoint(P3);
                if Index<>-1 then
                begin
                   Index:=(Index+1) mod Face.NumberOfpoints;
                   if Face.Point[index]=P2 then
                   begin
                      // face is oriented CCW
                      Index:=(Index+1) mod Face.NumberOfpoints;
                      OppPoint2:=Face.Point[index];
                      Index:=(Index+1) mod Face.NumberOfpoints;
                      OppPoint3:=Face.Point[index];
                   end else
                   begin
                      Index:=Face.IndexOfPoint(P2);
                      if Index<>-1 then
                      begin
                         Index:=(Index+1) mod Face.NumberOfpoints;
                         if Face.Point[index]=P3 then
                         begin
                            // face is oriented CW
                            Index:=(Index+1) mod Face.NumberOfpoints;
                            OppPoint3:=Face.Point[index];
                            Index:=(Index+1) mod Face.NumberOfpoints;
                            OppPoint2:=Face.Point[index];
                         end;
                      end;
                   end;
                end;
                break;
             end;
          end;
       end;
    end;{FindOpposingPoints}

    procedure AssembleTriangle(var Cols,Rows:Integer;var Grid:TFreeSubdivisionGrid;Face:TFreeSubdivisionControlface);
    var I,J,N        : Integer;
        Index        : Integer;
        Points       : TFasterList;
        Faces        : TFasterList;
        Child        : TFreeSubdivisionface;
        P            : TFreeSubdivisionPoint;
        InteriorPoint: TFreeSubdivisionPoint;
    begin
      // Initialize grid
      Cols:=0;
      Rows:=0;

      Points:=TFasterList.Create;
      Faces:=TFasterList.Create;
      for I:=1 to Face.ChildCount do
      begin
         Child:=Face.Child[I-1];
         Faces.Add(Child);
         for J:=1 to Child.NumberOfpoints do
         begin
            P:=Child.Point[J-1];
            if Points.SortedIndexOf(P)=-1 then Points.AddSorted(P);
         end;
      end;
      Faces.Sort;
      // Try to isolate the interior point
      InteriorPoint:=nil;
      for I:=1 to Points.Count do
      begin
         P:=Points[I-1];
         // check how many of the childfaces are connected (interior point must have 3)
         N:=0;
         for J:=1 to P.NumberOfFaces do if Faces.SortedIndexOf(P.Face[J-1])<>-1 then inc(N);
         if N=3 then
         begin
            InteriorPoint:=P;
            break;
         end;
      end;
      if Interiorpoint<>nil then
      begin
         Cols:=3;
         Rows:=3;
         Setlength(Grid,Rows);
         for I:=1 to Rows do
         begin
            Setlength(Grid[I-1],Cols);
            for J:=1 to Cols do Grid[I-1][J-1]:=nil;
         end;

         Grid[1][1]:=InteriorPoint;
         Child:=Face.Child[2];
         Index:=Child.IndexOfPoint(InteriorPoint);
         Grid[1][0]:=Child.Point[(index+1) mod 4];
         Grid[0][0]:=Child.Point[(index+2) mod 4];
         Grid[0][1]:=Child.Point[(index+3) mod 4];
         FindOpposingPoints(Grid[0][0],Grid[0][1],Grid[1][1],Grid[1][0],Grid[0][2],Grid[1][2]);
         FindOpposingPoints(Grid[0][1],Grid[1][1],Grid[1][0],Grid[0][0],Grid[2][1],Grid[2][0]);

         Grid[2][2]:=Grid[2][1];
         for I:=1 to Rows do
            for J:=1 to cols do if grid[I-1][j-1]=nil then
            begin
               Raise Exception.create(Userstring(98));
            end;
      end else MessageDlg(Userstring(99),mtError,[mbOk],0);
      Faces.Destroy;
      Points.Destroy;
    end;{AssembleTriangle}

    procedure ProcessGrid(Cols,Rows:Integer;Grid:TFreeSubdivisionGrid;ColorInd:Integer);
    // convert grid to a NURB
    var NURB,NURB2   : TFreeNURBsurface;
        I,J          : Integer;
        BottomRow    : array of TFreeSubdivisionPoint;
        TopRow       : array of TFreeSubdivisionPoint;
        LeftColumn   : array of TFreeSubdivisionPoint;
        RightColumn  : array of TFreeSubdivisionPoint;
        BottomLeft   : TFreeSubdivisionPoint;
        BottomRight  : TFreeSubdivisionPoint;
        TopLeft      : TFreeSubdivisionPoint;
        TopRight     : TFreeSubdivisionPoint;
        BottomPresent: Boolean;
        LeftPresent  : Boolean;
        RightPresent : Boolean;
        TopPresent   : Boolean;
        P            : T3DCoordinate;

        function PhantomPoint(BorderPoint,InnerPoint:T3DCoordinate):T3DCoordinate;
        begin
           Result.X:=2*BorderPoint.X-InnerPoint.X;
           Result.Y:=2*BorderPoint.Y-InnerPoint.Y;
           Result.Z:=2*BorderPoint.Z-InnerPoint.Z;
        end;{PhantomPoint}

        function CornerPoint(P5,P6,P8,P9:T3DCoordinate):T3DCoordinate;
        var P2,P3,P4,P7:T3DCoordinate;
        begin
           P2:=PhantomPoint(P5,P8);
           P3:=PhantomPoint(P6,P9);
           P4:=PhantomPoint(P5,P6);
           P7:=PhantomPoint(P8,P9);
           Result.X:=20*P5.X-4*P2.X-P3.X-4*P4.X-4*P6.X-P7.X-4*P8.X-P9.X;
           Result.Y:=20*P5.Y-4*P2.Y-P3.Y-4*P4.Y-4*P6.Y-P7.Y-4*P8.Y-P9.Y;
           Result.Z:=20*P5.Z-4*P2.Z-P3.Z-4*P4.Z-4*P6.Z-P7.Z-4*P8.Z-P9.Z;
        end;{CornerPoint}

    begin
      if (Cols>0) and (Rows>0) then
      begin
         Setlength(BottomRow,Cols);
         Setlength(TopRow,Cols);
         Setlength(LeftColumn,Rows);
         Setlength(RightColumn,Rows);

         // assemble bottom row to set tangency
         BottomPresent:=True;
         for I:=2 to Cols do
         begin
            FindOpposingPoints(Grid[Rows-2][I-2],Grid[Rows-1][I-2],Grid[Rows-1][I-1],Grid[Rows-2][I-1],BottomRow[I-2],BottomRow[I-1]);
            if (BottomRow[I-2]=nil) or (BottomRow[I-1]=nil) then BottomPresent:=false;
         end;
         RightPresent:=True;
         // assemble right column to set tangency
         for I:=2 to Rows do
         begin
            FindOpposingPoints(Grid[I-1][Cols-2],Grid[I-1][Cols-1],Grid[I-2][Cols-1],Grid[I-2][Cols-2],RightColumn[I-1],RightColumn[I-2]);
            if (RightColumn[I-1]=nil) or (RightColumn[I-2]=nil) then RightPresent:=false;
         end;
         // assemble top row
         TopPresent:=True;
         for I:=2 to Cols do
         begin
            FindOpposingPoints(Grid[1][I-1],Grid[0][I-1],Grid[0][I-2],Grid[1][I-2],TopRow[I-1],TopRow[I-2]);
            if (TopRow[I-2]=nil) or (TopRow[I-1]=nil) then TopPresent:=false;
         end;
         // Assemble left column
         LeftPresent:=True;
         for I:=2 to Rows do
         begin
            FindOpposingPoints(Grid[I-2][1],Grid[I-2][0],Grid[I-1][0],Grid[I-1][1],LeftColumn[I-2],LeftColumn[I-1]);
            if (LeftColumn[I-1]=nil) or (LeftColumn[I-2]=nil) then LeftPresent:=false;
         end;
         BottomLeft:=nil;
         BottomRight:=nil;
         TopLeft:=nil;
         TopRight:=nil;

         if BottomPresent and leftPresent then BottomLeft:=FindFourtPoint(LeftColumn[Rows-1],Grid[Rows-1][0],BottomRow[0]);               // find bottomleft cornerpoint
         if BottomPresent and RightPresent then BottomRight:=FindFourtPoint(RightColumn[Rows-1],Grid[Rows-1][Cols-1],BottomRow[Cols-1]);  // find bottomRight cornerpoint
         if TopPresent and leftPresent then TopLeft:=FindFourtPoint(LeftColumn[0],Grid[0][0],TopRow[0]);                                  // find Topleft cornerpoint
         if TopPresent and RightPresent then TopRight:=FindFourtPoint(RightColumn[0],Grid[0][Cols-1],TopRow[Cols-1]);                     // find TopRight cornerpoint

         NURB:=TFreeNURBsurface.Create;
         NURB.SetCapacity(Cols+2,Rows+2);
         NURB.ColCount:=Nurb.ColCapacity;
         NURB.RowCount:=Nurb.RowCapacity;
         for I:=1 to Rows do
         begin
            for J:=1 to COLS do
            begin
               NURB.Point[J,I]:=Grid[I-1][J-1].Coordinate;
            end;
         end;

         if SendTriangles then
         begin
            // check for special triangle case
            if (Grid[Rows-1][Cols-1]=Grid[Rows-1][Cols-2]) and
               (Grid[Rows-1][Cols-1]=Grid[Rows-2][Cols-1]) then
            begin
               Nurb.Point[Cols,Rows]:=Grid[Rows-1][Cols-1].LimitPoint;
               Nurb.Point[Cols-1,Rows]:=Grid[Rows-1][Cols-1].LimitPoint;
               Nurb.Point[Cols,Rows-1]:=Grid[Rows-1][Cols-1].LimitPoint;
               Nurb.RowCount:=Nurb.RowCount-1+1;
            end;
         end;


         if TopPresent then for I:=1 to Cols do Nurb.Point[I,0]:=TopRow[I-1].Coordinate
                       else for I:=1 to Cols do Nurb.Point[I,0]:=PhantomPoint(Nurb.Point[I,1],Nurb.Point[I,2]);
         if BottomPresent then for I:=1 to Cols do Nurb.Point[I,Rows+1]:=BottomRow[I-1].Coordinate
                          else for I:=1 to Cols do Nurb.Point[I,Rows+1]:=PhantomPoint(Nurb.Point[I,Rows],Nurb.Point[I,Rows-1]);
         if LeftPresent then for I:=1 to Rows do Nurb.Point[0,I]:=LeftColumn[I-1].Coordinate
                        else for I:=1 to Rows do Nurb.Point[0,I]:=PhantomPoint(Nurb.Point[1,I],Nurb.Point[2,I]);
         if RightPresent then for I:=1 to Rows do Nurb.Point[Cols+1,I]:=RightColumn[I-1].Coordinate
                         else for I:=1 to Rows do Nurb.Point[Cols+1,I]:=PhantomPoint(Nurb.Point[Cols,I],Nurb.Point[Cols-1,I]);

         if TopLeft<>nil then Nurb.Point[0,0]:=TopLeft.Coordinate
                         else Nurb.Point[0,0]:=CornerPoint(Nurb.Point[1,1],Nurb.Point[2,1],Nurb.Point[1,2],Nurb.Point[2,2]);
         if TopRight<>nil then Nurb.Point[Nurb.ColCount-1,0]:=TopRight.Coordinate
                          else Nurb.Point[Nurb.ColCount-1,0]:=CornerPoint(Nurb.Point[Nurb.Colcount-2,1],Nurb.Point[Nurb.Colcount-3,1],Nurb.Point[Nurb.Colcount-2,2],Nurb.Point[Nurb.Colcount-3,2]);
         if BottomLeft<>nil then Nurb.Point[0,Nurb.RowCount-1]:=BottomLeft.Coordinate
                            else Nurb.Point[0,Nurb.RowCount-1]:=CornerPoint(Nurb.Point[1,Nurb.Rowcount-2],Nurb.Point[2,Nurb.Rowcount-2],Nurb.Point[1,Nurb.Rowcount-3],Nurb.Point[2,Nurb.Rowcount-3]);
         if BottomRight<>nil then Nurb.Point[Nurb.ColCount-1,Nurb.RowCount-1]:=BottomRight.Coordinate
                             else Nurb.Point[Nurb.ColCount-1,Nurb.RowCount-1]:=CornerPoint(Nurb.Point[Nurb.Colcount-2,Nurb.Rowcount-2],Nurb.Point[Nurb.Colcount-3,Nurb.Rowcount-2],Nurb.Point[Nurb.Colcount-2,Nurb.Rowcount-3],Nurb.Point[Nurb.Colcount-3,Nurb.Rowcount-3]);

         NURB.ColDegree:=3;
         NURB.RowDegree:=3;
         NURB.SetUniformColKnotvector;
         NURB.SetUniformRowKnotvector;

         // Insert knots to force the patch to interpolate start and endknots
         for I:=1 to Nurb.ColDegree do Nurb.InsertColKnot(Nurb.Colknotvector[Nurb.ColDegree]);
         for I:=1 to Nurb.ColDegree do Nurb.InsertColKnot(Nurb.Colknotvector[Nurb.ColCount]);
         for I:=1 to Nurb.RowDegree do Nurb.InsertRowKnot(Nurb.Rowknotvector[Nurb.RowDegree]);
         for I:=1 to Nurb.RowDegree do Nurb.InsertRowKnot(Nurb.Rowknotvector[Nurb.RowCount]);
         // Delete old startpoints
         for I:=1 to Nurb.ColDegree do Nurb.DeleteColumn(0);
         for I:=1 to Nurb.ColDegree do Nurb.DeleteColumn(Nurb.ColCount-1);
         for I:=1 to Nurb.RowDegree do Nurb.DeleteRow(0);
         for I:=1 to Nurb.RowDegree do Nurb.DeleteRow(Nurb.RowCount-1);
         // Set knotvectors to open-knot vector type (standard interpolating form)
         Nurb.SetDefaultColKnotvector;
         Nurb.SetDefaultRowKnotvector;

         // Check all cornerpoints for irregular vertices
         {
         if TopLeft=nil then if not Grid[0][0].IsRegularNURBSPoint(CheckFaces) then Nurb.Point[0,0]:=LimitPoint(Grid[0][0]);
         if Topright=nil then if not Grid[0][Cols-1].IsRegularNURBSPoint(CheckFaces) then Nurb.Point[Cols+1,0]:=LimitPoint(Grid[0][Cols-1]);
         if BottomLeft=nil then if not Grid[Rows-1][0].IsRegularNURBSPoint(CheckFaces) then Nurb.Point[0,Rows+1]:=LimitPoint(Grid[Rows-1][0]);
         if bottomright=nil then if not Grid[Rows-1][Cols-1].IsRegularNURBSPoint(CheckFaces) then Nurb.Point[Cols+1,Rows+1]:=LimitPoint(Grid[Rows-1][Cols-1]);
         }
         {
         if TopLeft=nil then Nurb.Point[0,0]:=LimitPoint(Grid[0][0]);
         if Topright=nil then Nurb.Point[Cols+1,0]:=LimitPoint(Grid[0][Cols-1]);
         if BottomLeft=nil then Nurb.Point[0,Rows+1]:=LimitPoint(Grid[Rows-1][0]);
         if bottomright=nil then Nurb.Point[Cols+1,Rows+1]:=LimitPoint(Grid[Rows-1][Cols-1]);
         }
         Nurb.Point[0,0]:=Grid[0][0].LimitPoint;
         Nurb.Point[Cols+1,0]:=Grid[0][Cols-1].LimitPoint;
         Nurb.Point[0,Rows+1]:=Grid[Rows-1][0].LimitPoint;
         Nurb.Point[Cols+1,Rows+1]:=Grid[Rows-1][Cols-1].LimitPoint;
         IGESList.Add_Entity_128(NURB,ColorInd);
         if Owner.Visibility.ModelView=mvBoth then
         begin
            NURB2:=TFreeNURBsurface.Create;
            NURB2.SetCapacity(Nurb.ColCount,Nurb.RowCount);
            NURB2.ColCount:=Nurb2.ColCapacity;
            NURB2.RowCount:=Nurb2.RowCapacity;
            NURB2.ColDegree:=Nurb.ColDegree;
            NURB2.RowDegree:=Nurb.RowDegree;
            for I:=Nurb.ColCount downto 1 do
            begin
               for J:=Nurb.RowCount downto 1 do
               begin
                  P:=NURB.Point[I-1,J-1];
                  P.Y:=-P.Y;
                  NURB2.Point[NURB2.Colcount-I,Nurb2.RowCount-J]:=P;
               end;
            end;
            NURB2.SetDefaultColKnotvector;
            NURB2.SetDefaultRowKnotvector;
            IGESList.Add_Entity_128(NURB2,ColorInd);
            inc(NSurfaces);
            NURB2.Destroy;
         end;
         inc(NSurfaces);
         NURB.Destroy;
      end;
    end;{ProcessGrid}

begin
   Dialog:=TSaveDialog.Create(Owner);
   Dialog.InitialDir:=Owner.Preferences.ExportDirectory;
   Dialog.FileName:=ChangeFileExt(ExtractFilename(Owner.FileName),'.igs');
   Dialog.Filter:='IGES files (*.igs)|*.igs';
   dialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if Dialog.Execute then
   begin
      Prev:=Screen.Cursor;
      Screen.Cursor:=crHourglass;
      PrevLevel:=Owner.Surface.DesiredSubdivisionLevel;
      NSurfaces:=0;
      try
         Owner.Surface.DesiredSubdivisionLevel:=1;
         Owner.Surface.SubdivisionMode:=fmCatmullClark;
         if not Owner.Surface.Build then Owner.Surface.Rebuild;
         Owner.Preferences.ExportDirectory:=ExtractFilePath(Dialog.FileName);
         IGESList:=TFreeIGESList.Create;
         IGESList.IGESUnits:=Owner.ProjectSettings.ProjectUnits;
         IGESList.SystemID:='FREE!ship'+#32+VersionString(CurrentVersion);
         IGESList.FileCreatedBy:=Owner.ProjectSettings.ProjectFileCreatedBy;
         IGESList.FileName:=Dialog.FileName;
         // Build color table
         Layers:=TFasterList.Create;
         for I:=1 to Owner.NumberOfLayers do if (Owner.Layer[I-1].Visible) and (Owner.Layer[I-1].Count>0) then Layers.Add(Owner.Layer[I-1]);
         Layers.Sort;
         Setlength(ColorIndices,Layers.Count);
         for I:=1 to Layers.Count do
         begin
            Layer:=Layers[I-1];
            ColorIndices[I-1]:=IGESList.Add_Entity_314(Layer.Color);
         end;
         if MinimizeFaces then
         begin
            Owner.Surface.AssembleFacesToPatches(Layers,amNURBS,Assembled,NAssembled);
            CheckFaces:=TFasterList.Create;
            for I:=1 to NAssembled do
            begin
               FaceData:=Assembled[I-1];
               CheckFaces.Clear;
               Checkfaces.Capacity:=FaceData.NCols*FaceData.NRows;
               for J:=1 to Facedata.NRows do
                  for K:=1 to FaceData.NCols do CheckFaces.Add(Facedata.Faces[J-1][K-1]);
               if (FaceData.NCols>0) and (FaceData.NRows>0) then
               begin
                  if ((FaceData.NCols>1) and (FaceData.NRows>=1)) or
                     ((FaceData.NCols>=1) and (FaceData.NRows>1)) or
                     ((FaceData.NCols=1) and (FaceData.NRows=1) and (FaceData.Faces[0][0].NumberOfPoints=4)) then
                  begin
                     CtrlFace:=FaceData.Faces[0][0];
                     if Layers.SortedIndexOf(Ctrlface.Layer)<>-1 then ColorIndex:=ColorIndices[Layers.SortedIndexOf(Ctrlface.Layer)]
                                                                 else Colorindex:=0;
                     Owner.Surface.ConvertToGrid(FaceData,Cols,Rows,Grid);
                     ProcessGrid(Cols,Rows,Grid,ColorIndex);
                  end else
                  begin
                     CtrlFace:=FaceData.Faces[0][0];
                     if Layers.SortedIndexOf(Ctrlface.Layer)<>-1 then ColorIndex:=ColorIndices[Layers.SortedIndexOf(Ctrlface.Layer)]
                                                                 else Colorindex:=0;
                     if (CtrlFace.NumberOfpoints=3) and (SendTriangles) then
                     begin
                        AssembleTriangle(Cols,Rows,Grid,CtrlFace);
                        if (Cols>0) and (Rows>0) then ProcessGrid(Cols,Rows,Grid,ColorIndex);
                     end else
                     begin
                        Cols:=2;
                        Rows:=2;
                        Setlength(Grid,2);
                        Setlength(Grid[0],2);
                        Setlength(Grid[1],2);
                        for J:=1 to CtrlFace.ChildCount do
                        begin
                           Face:=CtrlFace.Child[J-1];
                           Grid[0][1]:=Face.Point[0];
                           Grid[0][0]:=Face.Point[1];
                           Grid[1][0]:=Face.Point[2];
                           Grid[1][1]:=Face.Point[3];
                           ProcessGrid(Cols,Rows,Grid,ColorIndex);
                        end;
                     end;
                  end;
               end;
            end;
            CheckFaces.Destroy;
         end else
         begin
            for I:=1 to Owner.Surface.NumberOfControlFaces do
            begin
               CtrlFace:=Owner.Surface.ControlFace[I-1];
               if Layers.SortedIndexOf(Ctrlface.Layer)<>-1 then ColorIndex:=ColorIndices[Layers.SortedIndexOf(Ctrlface.Layer)]
                                                           else Colorindex:=0;
               if CtrlFace.NumberOfpoints=4 then
               begin
                  FaceData.NCols:=1;
                  FaceData.NRows:=1;
                  Setlength(FaceData.Faces,1);
                  Setlength(FaceData.Faces[0],1);
                  FaceData.Faces[0][0]:=Ctrlface;
                  Owner.Surface.ConvertToGrid(FaceData,Cols,Rows,Grid);
                  ProcessGrid(Cols,Rows,Grid,ColorIndex);
               end else
               begin
                  Cols:=2;
                  Rows:=2;
                  Setlength(Grid,2);
                  Setlength(Grid[0],2);
                  Setlength(Grid[1],2);
                  for J:=1 to CtrlFace.ChildCount do
                  begin
                     Face:=CtrlFace.Child[J-1];
                     Grid[0][1]:=Face.Point[0];
                     Grid[0][0]:=Face.Point[1];
                     Grid[1][0]:=Face.Point[2];
                     Grid[1][1]:=Face.Point[3];
                     ProcessGrid(Cols,Rows,Grid,ColorIndex);
                  end;
               end;
            end;
         end;
         if NSurfaces>0 then
         begin
            IGESList.SaveToFile(ChangeFileExt(Dialog.Filename,'.igs'));
            MessageDlg('Exported '+IntToStr(NSurfaces)+' surfaces.',mtInformation,[mbOK],0);
         end else MessageDlg(Userstring(100),mtInformation,[mbOK],0);
         IGESList.Destroy;
         Layers.Destroy;
      finally
         Owner.Surface.DesiredSubdivisionLevel:=PrevLevel;
         Owner.Surface.SubdivisionMode:=fmQuadTriangle;
         if not Owner.Surface.Build then Owner.Surface.Rebuild;
         Screen.Cursor:=Prev;
         Owner.Redraw;
      end;
   end;
   Dialog.Destroy;
end;{TFreeEdit.File_ExportIGES}

// Creates a file to be read by the CFD program Michlet
procedure TFreeEdit.File_Export_Michlet;
var Dialog     : TFreeMichletOutputDialog;
    SaveDialog : TSaveDialog;
    UndoObject : TFreeUndoObject;
begin
   if not Owner.ProjectSettings.FMainparticularsHasBeenset then
   begin
      MessageDlg(Userstring(95),mtWarning,[mbOk],0);
      exit;
   end;
   // temporarily switch to metric units for michlet export
   if Owner.ProjectSettings.ProjectUnits=fuImperial then
   begin
      UndoObject:=CreateUndoObject(Userstring(101),false);
      Owner.ProjectSettings.ProjectUnits:=fuMetric;
   end else UndoObject:=nil;
   try
      if not Owner.ProjectSettings.DisableModelCheck then Model_Check(False);
      Dialog:=TFreeMichletOutputDialog.Create(Owner);
      ShowTranslatedValues(Dialog);
      // Hull
      Dialog.NumberOfStations:=31;
      Dialog.NumberOfWaterlines:=21;
      Dialog.Draft:=Owner.ProjectSettings.ProjectDraft;
      Dialog.Length:=Owner.ProjectSettings.ProjectLength;
      // Resistance
      Dialog.StartSpeed:=1;
      Dialog.EndSpeed:=5;
      Dialog.NumberOfSpeeds:=50;

      // Environment
      Dialog.G:=9.80665;
      Dialog.WaterDensity:=Owner.ProjectSettings.ProjectWaterDensity;
      Dialog.WaterDepth:=10000;
      // Waves
      Dialog.R0:=1.5*Dialog.Length;
      Dialog.R1:=5.0*Dialog.Length;
      Dialog.Beta:=22.5;
      Dialog.Nr:=100;
      Dialog.NBeta:=100;
      Dialog.X0:=1.5*Dialog.Length;
      Dialog.X1:=5.0*Dialog.Length;
      Dialog.Y0:=-5.0*Dialog.Length*tan(DegToRad(30));
      Dialog.Y1:=-Dialog.Y0;
      Dialog.Nx:=100;
      Dialog.Ny:=100;

      if Dialog.Execute(Owner) then
      begin
         SaveDialog:=TSaveDialog.Create(Owner);
         SaveDialog.InitialDir:=Owner.Preferences.ExportDirectory;
         SaveDialog.FileName:=ChangeFileExt(ExtractFilename(Owner.FileName),'.mlt');
         SaveDialog.Filter:='Michlet input file (*.mlt)|*.mlt';
         Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
         if SaveDialog.Execute then Dialog.SaveToFile(ChangeFileExt(SaveDialog.FileName,'.mlt'));
         SaveDialog.Destroy;
      end;
      Dialog.Destroy;
   finally
      if UndoObject<>nil then UndoObject.Restore;
   end;
end;{TFreeEdit.File_Export_Michlet}

procedure TFreeEdit.File_Import_MichletWaves;
var FFile      : TextFile;
    Grid       : array of array of T3DCoordinate;
    CtrlGrid   : array of array of TFreeSubdivisionControlPoint;
    I,J,K      : Integer;
    Nx,Ny      : Integer;
    Str        : AnsiString;
    Tmp        : string;
    Speed      : string;
    P,Min,Max  : T3DCoordinate;
    XArray     : array of TFloatType;
    Pts        : TFasterList;
    Layer      : TFreeSubdivisionLayer;
    AllZero    : boolean;
    DecrY      : Integer;
    MultFact   : TFloatType;
    Angle      : TFloatType;
    OpenDialog : TOpenDialog;
    PrevCursor : TCursor;
begin
   OpenDialog:=TOpenDialog.Create(Owner);
   OpenDialog.InitialDir:=Owner.Preferences.ImportDirectory;
   OpenDialog.Filter:='Michlet wave elevations file (*.mlt)|*.mlt';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then
   begin
      assignfile(FFile,Opendialog.Filename);
      Reset(FFile);
      Readln(FFile,Str);
      Nx:=0;
      Ny:=0;
      Speed:='';
      if Str='RECTANGULAR PATCH' then
      begin
         readln(FFile);
         readln(FFile,Speed);
         readln(FFile);

         //Read X0, X1, Nx
         Readln(FFile,Str);
         // X0
         Str:=Trim(Str);
         J:=Pos(',',Str);
         Tmp:=Copy(Str,1,J-1);
         Delete(Str,1,J);
         // X1
         Str:=Trim(Str);
         J:=Pos(',',Str);
         Tmp:=Copy(Str,1,J-1);
         Delete(Str,1,J);
         // Nx
         Nx:=StrToInt(Str);

         //Read Y0, Y1, Ny
         Readln(FFile,Str);
         Readln(FFile,Str);
         // Y0
         Str:=Trim(Str);
         J:=Pos(',',Str);
         Tmp:=Copy(Str,1,J-1);
         Delete(Str,1,J);
         // Y1
         Str:=Trim(Str);
         J:=Pos(',',Str);
         Tmp:=Copy(Str,1,J-1);
         Delete(Str,1,J);
         // Ny
         Ny:=StrToInt(Str);

         for I:=1 to 5 do readln(Ffile);

         Ny:=Ny div 2; // use only port half
         // Read X distances
         Setlength(XArray,Nx);
         Readln(FFile,Str);
         J:=Pos(',',Str);
         if J<>0 then Delete(Str,1,J);
         for I:=1 to Nx do
         begin
            Str:=Trim(Str);
            J:=Pos(',',Str);
            if J<>0 then
            begin
               Tmp:=Copy(Str,1,J-1);
               XArray[I-1]:=StrToFloat(Tmp);
               Delete(Str,1,J);
            end else if I=Nx then XArray[I-1]:=StrToFloat(Str);
         end;

         Setlength(Grid,Ny);
         // Now read all the wave elevations
         For J:=1 to Ny do
         begin
            Readln(FFile,Str);
            Setlength(Grid[J-1],Nx);
            for I:=0 to Nx do
            begin
               Str:=Trim(Str);
               K:=Pos(',',Str);
               if K<>0 then
               begin
                  Tmp:=Copy(Str,1,K-1);
                  Delete(Str,1,K);
                  if I=0 then
                  begin
                     if J=Ny then P.Y:=0
                             else P.Y:=StrToFloat(Tmp);

                  end else
                  begin
                     P.X:=XArray[I-1];
                     P.Z:=StrToFloat(Tmp);
                     Grid[J-1][I-1]:=P;
                  end;
               end else if I=Nx then
               begin
                  P.X:=XArray[I-1];
                  P.Z:=StrToFloat(Tmp);
                  Grid[J-1][I-1]:=P;
               end;
            end;
        end;
      end else if Str='SECTORIAL PATCH' then
      begin
         readln(FFile);
         readln(FFile,Speed);
         readln(FFile);

         //Read Nx
         Readln(FFile,Str);
         // X0
         Str:=Trim(Str);
         J:=Pos(',',Str);
         Tmp:=Copy(Str,1,J-1);
         Delete(Str,1,J);
         // X1
         Str:=Trim(Str);
         J:=Pos(',',Str);
         Tmp:=Copy(Str,1,J-1);
         Delete(Str,1,J);
         // Nx
         Nx:=StrToInt(Str);

         //Read Y0, Y1, Ny
         Readln(FFile,Str);
         Readln(FFile,Str);
         // Y0
         Str:=Trim(Str);
         J:=Pos(',',Str);
         Tmp:=Copy(Str,1,J-1);
         Delete(Str,1,J);
         // Y1
         Str:=Trim(Str);
         J:=Pos(',',Str);
         Tmp:=Copy(Str,1,J-1);
         Delete(Str,1,J);
         // Ny
         Ny:=StrToInt(Str);

         for I:=1 to 13 do readln(Ffile);

         Ny:=(Ny-1); // use only port half
         // Read Radia
         Setlength(XArray,Nx);
         Readln(FFile,Str);
         J:=Pos(',',Str);
         if J<>0 then Delete(Str,1,J);
         for I:=1 to Nx do
         begin
            Str:=Trim(Str);
            J:=Pos(',',Str);
            if J<>0 then
            begin
               Tmp:=Copy(Str,1,J-1);
               XArray[I-1]:=StrToFloat(Tmp);
               Delete(Str,1,J);
            end else if I=Nx then XArray[I-1]:=StrToFloat(Str);
         end;

         Setlength(Grid,Ny);
         // Now read all the wave elevations
         angle:=0;
         For J:=1 to Ny do
         begin
            Readln(FFile,Str);
            Setlength(Grid[J-1],Nx);
            for I:=0 to Nx do
            begin
               Str:=Trim(Str);
               K:=Pos(',',Str);
               if K<>0 then
               begin
                  Tmp:=Copy(Str,1,K-1);
                  Delete(Str,1,K);
                  if I=0 then
                  begin
                     if J=Ny then Angle:=0
                             else Angle:=-StrToFloat(Tmp);
                  end else
                  begin
                     P.X:=XArray[I-1]*Cos(DegToRad(Angle));
                     P.Y:=XArray[I-1]*Sin(DegToRad(Angle));
                     P.Z:=StrToFloat(Tmp);
                     Grid[J-1][I-1]:=P;
                  end;
               end else if I=Nx then
               begin
                  P.X:=XArray[I-1]*Cos(DegToRad(Angle));
                  P.Y:=XArray[I-1]*Sin(DegToRad(Angle));
                  //P.X:=XArray[I-1];
                  P.Z:=StrToFloat(Tmp);
                  Grid[J-1][I-1]:=P;
               end;
            end;
        end;
      end;
      if (Nx>0) and (Ny>0) then
      begin
         PrevCursor:=Screen.Cursor;
         Screen.Cursor:=crHourglass;
         Owner.Extents(Min,Max);
         // Search grid for strips wit zero wave-elevation height and leave these out
         MultFact:=1.0;

         Setlength(CtrlGrid,Ny);
         DecrY:=0;
         for I:=1 to Ny do
         begin
            AllZero:=True;
            for J:=1 to Nx do
            begin
               Grid[I-1][J-1].Z:=Grid[I-1][J-1].Z*MultFact;
               if abs(Grid[I-1][J-1].Z)>1e-3 then
               begin
                  AllZero:=False;
                  break;
               end;
            end;
            if AllZero then inc(DecrY);
         end;
         if DecrY>0 then dec(DecrY);

         // Add controlpoints
         Setlength(CtrlGrid,Ny);
         for I:=1+DecrY to Ny do
         begin
            Setlength(CtrlGrid[I-1],Nx);
            for J:=1 to Nx do
            begin
               if Owner.ProjectSettings.ProjectUnits=fuImperial then
               begin
                  // scale to feet
                  Grid[I-1][J-1].X:=Grid[I-1][J-1].X/Foot;
                  Grid[I-1][J-1].Y:=Grid[I-1][J-1].Y/Foot;
                  Grid[I-1][J-1].Z:=Grid[I-1][J-1].Z/Foot;
               end;
               Grid[I-1][J-1].X:=0.5*Owner.ProjectSettings.ProjectLength-Grid[I-1][J-1].X;
               Grid[I-1][J-1].Z:=Min.Z+Owner.ProjectSettings.ProjectDraft+Grid[I-1][J-1].Z;
               CtrlGrid[I-1][J-1]:=TFreeSubdivisionControlPoint.Create(Owner.Surface);
               Owner.Surface.AddControlPoint(CtrlGrid[I-1][J-1]);
               CtrlGrid[I-1][J-1].Coordinate:=Grid[I-1][J-1];
            end;
         end;

         Pts:=TFasterList.Create;
         Layer:=Owner.Surface.AddNewLayer;
         if Speed<>'' then Layer.Name:='Michlet waves, speed='+speed+' m/s'
                      else Layer.Name:='Michlet wave elevations, speed='+speed+' m/s';
         Layer.Color:=clAqua;
         Layer.UseInHydrostatics:=False;
         Layer.ShowInLinesplan:=False;
         Layer.UseForIntersections:=False;
         // Add faces to controlpoints
         for I:=DecrY+2 to Ny do
         begin
            Setlength(CtrlGrid[I-1],Nx);
            for J:=2 to Nx do
            begin
               Pts.Clear;
               Pts.Add(CtrlGrid[I-1][J-1]);
               Pts.Add(CtrlGrid[I-1][J-2]);
               Pts.Add(CtrlGrid[I-2][J-2]);
               Pts.Add(CtrlGrid[I-2][J-1]);
               Owner.Surface.AddControlFace(Pts,True,Layer);
            end;
         end;
         // set cornerpoints
         for I:=1+DecrY to Ny do
         begin
            for J:=1 to Nx do
            begin
               if CtrlGrid[I-1][J-1].NumberOfFaces=1 then
                  CtrlGrid[I-1][J-1].VertexType:=svCorner;
            end;
         end;
         Pts.Destroy;
         Owner.Draw;
         Screen.Cursor:=PrevCursor;
      end else MessageDlg(Userstring(102),mtError,[mbOk],0);
      CloseFile(FFile);
      Owner.FileChanged:=True;
      if Assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(self);
   end;
   OpenDialog.Destroy;
end;{TFreeEdit.File_Import_MichletWaves}

procedure TFreeEdit.File_ExportObj;
var SaveDialog : TSaveDialog;
    Strings    : TStringlist;
begin
   SaveDialog:=TSaveDialog.Create(Owner);
   SaveDialog.InitialDir:=Owner.Preferences.ExportDirectory;
   SaveDialog.FileName:=ChangeFileExt(ExtractFilename(Owner.FileName),'.obj');
   SaveDialog.Filter:='Wavefront file (*.Obj)|*.Obj|Controlnet to wavefront file (*.obj)|*.obj';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then
   begin
      Owner.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
      Strings:=TStringlist.Create;
      Owner.Surface.ExportObjFile(SaveDialog.FilterIndex=2,Strings);
      Strings.SaveToFile(ChangeFileExt(Savedialog.FileName,'.obj'));
      Strings.Destroy;
   end;
   SaveDialog.Destroy;
end;{TFreeEdit.File_ExportObj}

// Exports all intersections to a textfile as 3D points
procedure TFreeEdit.File_ExportOffsets;
var SaveDialog : TSaveDialog;
    Strings    : TStringlist;
    I          : integer;

    procedure SendSpline(Spline:TFreespline);
    var J      : integer;
        Str    : string;
        P      : T3DCoordinate;
    begin
      for J:=1 to Spline.NumberOfPoints do
      begin
         P:=Spline.Point[J-1];
         Str:='        '+MakeLength(P.X,4,10)+#32+MakeLength(P.Y,4,10)+#32+MakeLength(P.Z,4,10);
         if Spline.Knuckle[J-1] then Str:=Str+'    KNUCKLE';
         Strings.Add(Str);
      end;
    end;{SendSpline}

    procedure SendIntersection(Intersection:TFreeIntersection);
    var I      : integer;
        Str    : string;
        Spline : TFreeSpline;
    begin
       if not Intersection.Build then Intersection.Rebuild;
       if Intersection.Count>0 then
       begin
          Str:=Intersection.Description;
          Strings.Add(Str);
          if Intersection.Count>1 then Strings.Add(IntToStr(Intersection.Count)+' segments.');
          for I:=1 to Intersection.count do
          begin
             Spline:=Intersection.Items[I-1];
             if Intersection.Count>1 then Strings.Add('SEGMENT '+IntToStr(I));
             SendSpline(Spline);
          end;
       end;
    end;{SendIntersection}

begin
   SaveDialog:=TSaveDialog.Create(Owner);
   SaveDialog.InitialDir:=Owner.Preferences.ExportDirectory;
   SaveDialog.FileName:=ChangeFileExt(ExtractFilename(Owner.FileName),'.txt');
   SaveDialog.Filter:='Offsets as 3D points (*.Txt)|*.txt';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then
   begin
      Owner.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
      Strings:=TStringlist.Create;
      for I:=1 to Owner.NumberofStations do SendIntersection(Owner.Station[I-1]);
      for I:=1 to Owner.NumberofButtocks do SendIntersection(Owner.Buttock[I-1]);
      for I:=1 to Owner.NumberofWaterlines do SendIntersection(Owner.Waterline[I-1]);
      for I:=1 to Owner.NumberofDiagonals do SendIntersection(Owner.Diagonal[I-1]);
      for I:=1 to Owner.NumberOfControlCurves do
      begin
         Strings.Add('CONTROLCURVE');
         SendSpline(Owner.ControlCurve[I-1].Curve);
      end;
      Strings.SaveToFile(ChangeFileExt(Savedialog.FileName,'.txt'));
      Strings.Destroy;
   end;
   SaveDialog.Destroy;
end;{TFreeEdit.File_ExportOffsets}

// Export the surface to a STL file
//
// The native STL format has to fulfill the following specifications:
// 1. The normal and each vertex of every facet are specified by three coordinates each,
//    so there is a total of 12 numbers stored for each facet.
// 2. Each facet is part of the boundary between the interior and the exterior of the object.
//    The orientation of the facets is specified redundantly in two ways which must be consistent.
//    First, the direction of the normal is outward. Second, the vertices are listed in
//    counterclockwise order when looking at the object from the outside.
// 3. Each triangle must share two vertices with each of its adjacent triangles.
//    This is known as vertex-to-vertex rule.
// 4. The object represented must be located in the all-positive octant (all vertex coordinates
//    must be positive).

procedure TFreeEdit.File_ExportSTL;
var SaveDialog : TSaveDialog;
    FFile      : TextFile;
    I,J,K,L    : Integer;
    Layer      : TFreeSubdivisionLayer;
    Face       : TFreeSubdivisionControlface;
    Child      : TFreeSubdivisionface;

    procedure Addfacet(P1,P2,P3:TFreeSubdivisionPoint);
    var Normal:T3DCoordinate;
    begin
       Normal:=UnifiedNormal(p1.Coordinate,P2.Coordinate,P3.Coordinate);
       Write(FFile,'  facet normal ');
       writeln(FFile,Truncate(normal.X,4)+#32+Truncate(normal.Y,4)+#32+Truncate(normal.Z,4));
       writeln(FFile,'    outer loop');
       writeln(FFile,'      vertex '+Truncate(P1.Coordinate.X,4)+#32+Truncate(P1.Coordinate.Y,4)+#32+Truncate(P1.Coordinate.Z,4));
       writeln(FFile,'      vertex '+Truncate(P2.Coordinate.X,4)+#32+Truncate(P2.Coordinate.Y,4)+#32+Truncate(P2.Coordinate.Z,4));
       writeln(FFile,'      vertex '+Truncate(P3.Coordinate.X,4)+#32+Truncate(P3.Coordinate.Y,4)+#32+Truncate(P3.Coordinate.Z,4));
       writeln(FFile,'    endloop');
       Writeln(FFile,'  endfacet');
       

    end;{Addfacet}

begin
   SaveDialog:=TSaveDialog.Create(Owner);
   SaveDialog.InitialDir:=Owner.Preferences.ExportDirectory;
   SaveDialog.FileName:=ChangeFileExt(ExtractFilename(Owner.FileName),'.stl');
   SaveDialog.Filter:='STL file (*.stl)|*.stl';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then
   begin
      Owner.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
      AssignFile(FFile,Changefileext(SaveDialog.FileName,'.stl'));
      {$I-}Rewrite(FFile);{$I+}
      if IOResult=0 then
      begin
         // perform modelcheck to ensure normals point outward
         writeln(FFile,'solid');
         if not Owner.ProjectSettings.DisableModelCheck then Model_Check(False);
         for I:=1 to Owner.Surface.NumberOfLayers do
         begin
            Layer:=owner.Surface.Layer[I-1];
            if Layer.Visible then for J:=1 to Layer.Count do
            begin
               Face:=Layer.Items[J-1];
               for K:=1 to Face.ChildCount do
               begin
                  Child:=face.Child[K-1];
                  For L:=3 to Child.NumberOfpoints do AddFacet(Child.Point[0],Child.Point[L-2],Child.Point[L-1]);
               end;
            end;
         end;
         writeln(FFile,'endsolid');
         Closefile(FFile);
      end else MessageDlg(Userstring(97),mtError,[mbOk],0);
   end;
   SaveDialog.Destroy;

end;{TFreeEdit.File_ExportSTL}

// imports a Carene XYZ file and creates a multichine boat with developable surfaces
procedure TFreeEdit.File_ImportCarene;
var OpenDialog : TOpenDialog;
    Answer     : Word;
    Str        : string;
    I          : integer;
    LineNr     : Integer;
    P          : T3DCoordinate;
    FFile      : TextFile;
    Chines     : TFasterList;
    Spline     : TFreeSpline;
begin
   OpenDialog:=TOpenDialog.Create(Owner);
   OpenDialog.InitialDir:=Owner.Preferences.ImportDirectory;
   OpenDialog.Filter:='Carene XYZ files (*.xyz)|*.xyz';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then
   begin
      if Owner.FileChanged then
      begin
         Answer:=MessageDlg(Userstring(103)+EOL+Userstring(104),mtConfirmation,[mbYes,mbNo,mbCancel],0);
         if Answer=mrCancel then
         begin
            OpenDialog.Destroy;
            exit;
         end;
         if Answer=mrYes then
         begin
            File_SaveAs;
            if Owner.FileChanged then
            begin
               // Apparently saving was not successfull, abort
               OpenDialog.Destroy;
               exit;
            end;
         end;
      end;
      CreateUndoObject(Userstring(105),True);
      Owner.Clear;
      assignFile(FFile,ChangeFileExt(Opendialog.FileName,'.xyz'));
      {$I-}Reset(FFile);{$I+}
      if IOResult=0 then
      begin
         Owner.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
         try
            LineNr:=1;
            Readln(FFile,Str);
            // first 18 characters are description
            Str:=Copy(Str,1,18);
            Str:=Trim(Str);
            Owner.ProjectSettings.ProjectName:=Str;
            Chines:=TFasterList.Create;
            while not EOF(FFile) do
            begin
               Readln(FFile,Str);
               inc(LineNr);
               if Pos('LINE',Str)=1 then
               begin
                  // New chine
                  // skip one line
                  if not EOF(FFile) then
                  begin
                     Readln(FFile);
                     inc(LineNr);
                  end;
                  if not EOF(FFile) then
                  begin
                     Spline:=TFreeSpline.Create;
                     Chines.Add(Spline);

                     repeat
                        Readln(FFile,Str);
                        repeat
                           I:=Pos(#9,Str);
                           if I<>0 then Str[I]:=#32;
                        until I=0;
                        inc(LineNr);
                        if Str<>'' then
                        begin
                           P.X:=ReadFloatFromStr(LineNr,Str);
                           P.Y:=ReadFloatFromStr(LineNr,Str);
                           P.Z:=ReadFloatFromStr(LineNr,Str);
                           Spline.Add(P);
                           Str:=#32;
                        end;
                     until (EOF(FFile)) or (Str='');
                  end;
               end;
            end;
            Owner.ImportChines(8,Chines);
            Chines.Destroy;
         finally
            CloseFile(FFile);
            Owner.Filename:=ChangeFileExt(Opendialog.FileName,'.fbm');
         end;
      end else
      begin
         MessageDlg(Userstring(106),mtError,[mbOk],0);
      end;
   end;
   OpenDialog.Destroy;
end;{TFreeEdit.File_ImportCarene}

// Import chines from a textfile and fit a surface through them
procedure TFreeEdit.File_ImportChines;
var OpenDialog : TOpenDialog;
    Answer     : Word;
    Str        : string;
    I          : integer;
    LineNr     : Integer;
    P          : T3DCoordinate;
    FFile      : TextFile;
    Chines     : TFasterList;
    Spline     : TFreeSpline;
begin
   OpenDialog:=TOpenDialog.Create(Owner);
   OpenDialog.InitialDir:=Owner.Preferences.ImportDirectory;
   OpenDialog.Filter:='Text files (*.txt)|*.txt';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then
   begin
      if Owner.FileChanged then
      begin
         Answer:=MessageDlg(Userstring(103)+EOL+Userstring(104),mtConfirmation,[mbYes,mbNo,mbCancel],0);
         if Answer=mrCancel then
         begin
            OpenDialog.Destroy;
            exit;
         end;
         if Answer=mrYes then
         begin
            File_SaveAs;
            if Owner.FileChanged then
            begin
               // Apparently saving was not successfull, abort
               OpenDialog.Destroy;
               exit;
            end;
         end;
      end;
      CreateUndoObject(Userstring(107),True);
      Owner.Clear;
      assignFile(FFile,ChangeFileExt(Opendialog.FileName,'.txt'));
      {$I-}Reset(FFile);{$I+}
      if IOResult=0 then
      begin
         Owner.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
         LineNr:=1;
         Chines:=TFasterList.Create;
         try
            try
               // first read unit information; 0=metric, 1=imperial
               readln(FFile,I);
               if I in [0,1] then Owner.ProjectSettings.ProjectUnits:=TFreeUnitType(I)
                             else MessageDlg(Userstring(108),mtError,[mbOk],0);
               Spline:=TFreeSpline.Create;
               repeat
                  Readln(FFile,Str);
                  repeat
                     i:=Pos(#9,Str);
                     if I<>0 then str[I]:=#32;
                  until I=0;
                  inc(LineNr);
                  Str:=Trim(Uppercase(Str));
                  if (Str<>'') and (Str<>'EOF') then
                  begin
                     P.X:=ReadFloatFromStr(LineNr,Str);
                     P.Y:=ReadFloatFromStr(LineNr,Str);
                     P.Z:=ReadFloatFromStr(LineNr,Str);
                     Spline.Add(P);
                     Str:=#32;
                  end else if Str='' then
                  begin
                     if Spline.NumberOfPoints>1 then Chines.Add(Spline)
                                                else Spline.Destroy;
                     Spline:=TFreeSpline.Create;
                  end;
               until (Str='EOF') or (EOF(FFile));
               if Spline.NumberOfPoints>1 then Chines.Add(Spline)
                                          else Spline.Destroy;
            except
               MessageDlg('Error on line '+IntToStr(LineNr)+' in file '+Opendialog.Filename,mtError,[mbOk],0);
            end;
            Owner.ImportChines(8,Chines);
            Chines.Destroy;
         finally
            CloseFile(FFile);
            Owner.Filename:=ChangeFileExt(Opendialog.FileName,'.fbm');
            if Assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(self);
         end;
      end else
      begin
         MessageDlg(Userstring(106),mtError,[mbOk],0);
      end;
   end;
   OpenDialog.Destroy;
end;{TFreeEdit.File_ImportChines}

// Import a Freeship Exchange Format (FEF) file
procedure TFreeEdit.File_ImportFEF;
var OpenDialog : TOpenDialog;
    Answer     : word;
    Strings    : TStringList;
    Str        : string;
    LineNr,I   : integer;
begin
   OpenDialog:=TOpenDialog.Create(Owner);
   OpenDialog.InitialDir:=Owner.Preferences.ImportDirectory;
   OpenDialog.Filter:='FREE!ship Exchange Format file (*.Fef)|*.Fef';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then
   begin
      if Owner.FileChanged then
      begin
         Answer:=MessageDlg(Userstring(103)+EOL+Userstring(104),mtConfirmation,[mbYes,mbNo,mbCancel],0);
         if Answer=mrCancel then
         begin
            OpenDialog.Destroy;
            exit;
         end;
         if Answer=mrYes then
         begin
            File_SaveAs;
            if Owner.FileChanged then
            begin
               // Apparently saving was not successfull, abort
               OpenDialog.Destroy;
               exit;
            end;
         end;
      end;
      Owner.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
      CreateUndoObject(Userstring(109),True);
      Owner.Clear;
      Strings:=TStringList.Create;
      Strings.LoadFromFile(OpenDialog.Filename);
      LineNr:=-1;
      // Read general information and mainparticulars
      inc(LineNr);
      Owner.ProjectSettings.ProjectName:=Strings[LineNr];
      inc(LineNr);
      Owner.ProjectSettings.ProjectDesigner:=Strings[LineNr];
      inc(LineNr);
      Owner.ProjectSettings.FProjectFileCreatedBy:=Strings[LineNr];
      inc(LineNr);
      Owner.ProjectSettings.FProjectComment:=Strings[LineNr];
      Inc(LineNr);
      Str:=Strings[LineNr];
      Owner.ProjectSettings.ProjectLength:=ReadFloatfromStr(LineNr,Str);
      Owner.ProjectSettings.ProjectBeam:=ReadFloatfromStr(LineNr,Str);
      Owner.ProjectSettings.ProjectDraft:=ReadFloatfromStr(LineNr,Str);
      Owner.ProjectSettings.ProjectWaterDensity:=ReadFloatfromStr(LineNr,Str);
      Owner.ProjectSettings.ProjectAppendageCoefficient:=ReadFloatfromStr(LineNr,Str);
      I:=ReadIntfromStr(LineNr,Str);
      Owner.ProjectSettings.FProjectUnits:=TFreeUnitType(I);
      Owner.ProjectSettings.FMainparticularsHasBeenset:=ReadBoolfromStr(LineNr,Str);
      I:=ReadIntfromStr(LineNr,Str);
      Owner.FPrecision:=TFreePrecisionType(I);
      Owner.Surface.ImportFEFFile(Strings,LineNr);
      Strings.Destroy;
      Owner.FileName:=Opendialog.FileName;
      Owner.Build:=False;
      Owner.RebuildModel;
      if Assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(self);
   end;
   OpenDialog.Destroy;
end;{TFreeEdit.File_ImportFEF}

// Imports a file created with Carlssons's Hulls program
procedure TFreeEdit.File_ImportHull;
var OpenDialog : TOpenDialog;
    Answer     : Word;
begin
   OpenDialog:=TOpenDialog.Create(Owner);
   OpenDialog.InitialDir:=Owner.Preferences.ImportDirectory;
   OpenDialog.Filter:='Carlsson Hull files (*.hul)|*.hul';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then
   begin
      if Owner.FileChanged then
      begin
         Answer:=MessageDlg(Userstring(103)+EOL+Userstring(104),mtConfirmation,[mbYes,mbNo,mbCancel],0);
         if Answer=mrCancel then
         begin
            OpenDialog.Destroy;
            exit;
         end;
         if Answer=mrYes then
         begin
            File_SaveAs;
            if Owner.FileChanged then
            begin
               // Apparently saving was not successfull, abort
               OpenDialog.Destroy;
               exit;
            end;
         end;
      end;
      CreateUndoObject(UserString(110),True);
      File_ImportHull(OpenDialog.FileName,False);
      Owner.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
   end;
   OpenDialog.Destroy;
end;{TFreeEdit.File_ImportHull}

procedure TFreeEdit.File_ImportHull(Filename:string;Quiet:Boolean);
var I,J        : integer;
    NBulkHeads : integer;
    P,Min,Max  : T3DCoordinate;
    FFile      : TextFile;
    NoChines   : integer;
    Value      : TFloatType;
    Points     : array of array of T3DCoordinate;
    Chines     : TFasterList;
    Spline     : TFreeSpline;
    Str        : string;
    Skip       : Boolean;
begin
   Owner.Clear;
   assignFile(FFile,ChangeFileExt(FileName,'.hul'));
   {$I-}Reset(FFile);{$I+}
   if IOResult=0 then
   begin
      try
         Readln(FFile,NoChines);
         NBulkHeads:=5;
         Setlength(Points,NBulkHeads);
         for I:=1 to NBulkHeads do
         begin
            Setlength(Points[I-1],NoChines);
            for J:=1 to NoChines do
            begin
               Readln(FFile,P.Y);
               Readln(FFile,P.Z);
               Readln(FFile,P.X);
               // scale from inches to meters
               P.X:=P.X*0.0254;
               P.Y:=P.Y*0.0254;
               P.Z:=P.Z*0.0254;
               if (I=1) and (J=1) then
               begin
                  Min:=P;
                  Max:=Min;
               end else MinMax(P,Min,Max);
               Points[I-1][J-1]:=P;
            end;
         end;
         Readln(FFile);
         if Quiet then Skip:=True else Skip:=MessageDlg(Userstring(111),mtConfirmation,[mbYes,mbNo],0)=mrNo;
         if not skip then
         begin
            NBulkHeads:=13;
            Setlength(Points,NBulkHeads);
            for I:=1 to NBulkHeads do
            begin
               Setlength(Points[I-1],NoChines);
               for J:=1 to NoChines do
               begin
                  Readln(FFile,P.Y);
                  Readln(FFile,P.Z);
                  Readln(FFile,P.X);
                  // scale from inches to meters
                  P.X:=P.X*0.0254;
                  P.Y:=P.Y*0.0254;
                  P.Z:=P.Z*0.0254;
                  if (I=1) and (J=1) then
                  begin
                     Min:=P;
                     Max:=Min;
                  end else MinMax(P,Min,Max);
                  Points[I-1][J-1]:=P;
               end;
            end;
         end else
         begin
            for I:=1 to 13 do for J:=1 to NoChines do
            begin
               Readln(FFile);
               Readln(FFile);
               Readln(FFile);
            end;
         end;

         Chines:=TFasterlist.Create;
         for I:=1 to NoChines do
         begin
            for J:=1 to NBulkheads do
            begin
               P:=Points[J-1,I-1];
               P.X:=-P.X+Max.X;
               Points[J-1,I-1]:=P;
            end;
            Spline:=TFreeSpline.Create;
            Chines.Add(Spline);
            for J:=1 to NBulkheads do
            begin
               P:=Points[J-1,I-1];
               Spline.Add(P);
               Spline.Knuckle[J-1]:=False;
            end;
         end;
         Owner.ImportChines(NBulkheads,Chines);
         Chines.Destroy;
         // read stations
         for I:=1 to 8 do
         begin
            Readln(FFile,Value);
            Intersection_Add(fiStation,-Value*0.024+Max.X);
         end;

         // Skip rig info
         for I:=1 to 9 do Readln(FFile);

         // Read designer info
         Readln(FFile,Str);
         Owner.ProjectSettings.ProjectDesigner:=Str;
         Readln(FFile,Str);
         Owner.ProjectSettings.ProjectName:=Str;
      finally
         CloseFile(FFile);
         Owner.ProjectSettings.ProjectWaterDensity:=1.0;
         Owner.ProjectSettings.ProjectUnits:=fuImperial;
         Owner.ProjectSettings.ProjectDraft:=1.0;
         Owner.FileName:=ChangeFileExt(FileName,'');
         Owner.Draw;
      end;
   end else
   begin
      MessageDlg(Userstring(106),mtError,[mbOk],0);
   end;
end;{TFreeEdit.File_ImportHull}

// Import a partfile and add it to the current geometry
procedure TFreeEdit.File_ImportPart;
var OpenDialog    : TOpenDialog;
    PartFile      : TFreeFileBuffer;
    Undo          : TFreeUndoObject;
    PartUnits     : TFreeUnitType;
    Changed       : Boolean;
    Crease        : Boolean;
    I,J,N,Np      : Integer;
    Ind1,Ind2     : Integer;
    LayerID       : Integer;
    PartVersion   : TFreeFileversion;
    Str           : string;
    Scale         : TFloatType;
    Points        : TFasterList;
    Edges         : TFasterList;
    Layers        : TFasterList;
    FacePoints    : TFasterList;
    Edge          : TFreeSubdivisionControlEdge;
    P1,P2         : TFreeSubdivisionControlPoint;
    Curve         : TFreeSubdivisionControlCurve;
    Layer         : TFreeSubdivisionLayer;
    PrevCursor    : TCursor;

begin
   OpenDialog:=TOpenDialog.Create(Owner);
   OpenDialog.InitialDir:=Owner.Preferences.ImportDirectory;
   OpenDialog.Filter:='FREE!ship geometry part (*.Part)|*.part';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then
   begin
      PartFile:=TFreeFileBuffer.Create;
      Owner.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
      Changed:=False;
      Undo:=CreateUndoObject(Userstring(112),false);
      Partfile.LoadFromFile(ChangeFileExt(OpenDialog.FileName,'.part'));
      Partfile.Load(Str);
      if Str='FREE!ship partfile' then
      begin
         // Load fileversion
         Partfile.Load(I);
         if I<=Ord(CurrentVersion) then
         begin
            PrevCursor:=Screen.Cursor;
            Screen.Cursor:=crHourglass;
            try
               Partversion:=TFreeFileVersion(I);
               Partfile.Version:=PartVersion;
               Points:=TFasterList.Create;
               Edges:=TFasterList.Create;
               Layers:=TFasterList.Create;
               // Load units
               Partfile.Load(I);
               PartUnits:=TFreeUnitType(I);
               if PartUnits<>Owner.ProjectSettings.ProjectUnits then
               begin
                  if PartUnits=fuMetric then Scale:=1/Foot  // Part units=metric and projectunits=imperial, scale from meters to feet
                                        else scale:=Foot;   // Part units=imperial and projectunits=metric, scale from feet to meters
               end else Scale:=1.0;
               // Load number of layers
               Partfile.Load(N);
               Layers.Capacity:=N;
               for I:=1 to N do
               begin
                  Layer:=Owner.Surface.AddNewLayer;
                  LayerID:=Layer.LayerID;
                  Layer.LoadBinary(Partfile);
                  Layer.LayerID:=LayerID;
                  Layers.Add(Layer);
                  Changed:=True;
               end;
               // Number of controlpoints
               Partfile.Load(N);
               Points.Capacity:=N;
               for I:=1 to N do
               begin
                  P2:=TFreeSubdivisionControlPoint.Create(Owner.Surface);
                  Owner.Surface.AddControlPoint(P2);
                  P2.LoadBinary(PartFile);
                  P2.Coordinate:=ScalePoint(Scale,P2.Coordinate);
                  Points.Add(P2);
                  Changed:=True;
               end;
               // Load control edges
               Partfile.Load(N);
               Edges.Capacity:=N;
               for I:=1 to N do
               begin
                  Partfile.Load(Ind1);
                  Partfile.Load(Ind2);
                  if (Ind1<>-1) and (Ind2<>-1) then
                  begin
                     P1:=Points[ind1];
                     P2:=Points[ind2];
                     Edge:=Owner.Surface.AddControlEdge(P1,P2);
                  end else Edge:=nil;
                  Partfile.Load(Crease);
                  if Edge<>nil then Edge.Crease:=Crease;
                  Changed:=True;
               end;
               // Load controlfaces
               Partfile.Load(N);
               FacePoints:=TFasterList.Create;
               for I:=1 to N do
               begin
                  Partfile.Load(Np);
                  FacePoints.Clear;
                  FacePoints.Capacity:=N;
                  for J:=1 to Np do
                  begin
                     Partfile.Load(Ind1);
                     P2:=Points[ind1];
                     FacePoints.Add(P2);
                  end;
                  Partfile.Load(Ind2);
                  Layer:=Layers[ind2];
                  Owner.Surface.AddControlFace(FacePoints,False,Layer);
               end;
               for I:=1 to Edges.Count do
               begin
                  Edge:=Edges[I-1];
                  if (Edge.NumberOfFaces<>2) and (not Edge.Crease) then
                     Edge.Crease:=true;
               end;
               // Load controlcurves
               Partfile.Load(N);
               for I:=1 to N do
               begin
                  Partfile.Load(Np);
                  if Np>1 then
                  begin
                     Curve:=TFreeSubdivisionControlCurve.Create(Owner.Surface);
                     Owner.Surface.AddControlCurve(Curve);
                     for J:=1 to Np do
                     begin
                        Partfile.Load(Ind1);
                        P2:=Points[ind1];
                        Curve.AddPoint(P2);
                        if J>1 then
                        begin
                           P1:=Curve.ControlPoint[J-2];
                           Edge:=Owner.Surface.EdgeExists(P1,P2) as TFreeSubdivisionControlEdge;
                           if Edge<>nil then edge.Curve:=Curve;
                        end;
                     end;
                  end;
               end;
               FacePoints.Destroy;
               Points.Destroy;
               Edges.Destroy;
               Layers.Destroy;
            finally
               Screen.Cursor:=Prevcursor;
            end;
            if Changed then
            begin
               if Assigned(Owner.Surface.OnChangeLayerData) then Owner.Surface.OnChangeLayerData(Owner.Surface);
               Undo.Accept;
               Owner.Build:=False;
               Owner.Draw;
               Owner.FileChanged:=True;
               if assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(Owner);
            end;
         end else MessageDlg(UserString(113),mtError,[mbOk],0);
      end else MessageDlg(Userstring(114),mtError,[mbOk],0);
      if not Changed then Undo.Delete;
      Partfile.Destroy;
   end;
   OpenDialog.Destroy;
end;{TFreeEdit.File_ImportPart}

// Imports a PolyCad file
procedure TFreeEdit.File_ImportPolycad;
var OpenDialog : TOpenDialog;
    Answer     : Word;
    PrevCursor : TCursor;
    Strings    : TStringList;
    I,J,K,N    : Integer;
    Cols,Rows  : Integer;
    Index      : Integer;
    NSurfaces  : Integer;
    Indices    : array of Integer;
    Str,Tmp    : String;
    Abort      : Boolean;
    Points     : TFreeCoordinateGrid;
    Value      : TFloatType;
    P          : T3DCoordinate;

    function NextLine:string;
    begin
       if Index+1<Strings.Count then
       begin
          inc(Index);
          Result:=Strings[index];
       end else
       begin
          Result:='';
          Abort:=True;
          MessageDlg(UserString(115),mtError,[mbOk],0);
       end;
    end;{NextLine}

    Function GetInteger(str:string):Integer;
    var Index:Integer;
    begin
      Index:=Pos('=',Str);
      Result:=0;
      if Index<>0 then
      begin
         Str:=Copy(Str,Index+1,Length(Str)-Index);
         Val(Str,Result,Index);
         if Index<>0 then
         begin
            MessageDlg(Userstring(116)+#32+IntToStr(I),mtError,[mbOk],0);
            Abort:=True;
         end;
      end else Abort:=True;
    end;{GetInteger}

    Function GetFloat(str:string):TFloatType;
    var Index:Integer;
    begin
      Index:=Pos('=',Str);
      Result:=0;
      if Index<>0 then
      begin
         Str:=Copy(Str,Index+1,Length(Str)-Index);
         Val(Str,Result,Index);
         if Index<>0 then
         begin
            MessageDlg(Userstring(117)+#32+IntToStr(I),mtError,[mbOk],0);
            Abort:=True;
         end;
      end else Abort:=True;
    end;{GetFloat}

    function NextParameter(var input:string):string;
    var Index:Integer;
    begin
       Index:=pos(#32,Input);
       if Index<>0 then
       begin
          Result:=Copy(Input,1,Index-1);
          Delete(Input,1,Index);
          Input:=Trim(Input);
       end else
       begin
          Result:='';
          Abort:=True;
       end;
    end;{NextParameter}

begin
   OpenDialog:=TOpenDialog.Create(Owner);
   OpenDialog.InitialDir:=Owner.Preferences.ImportDirectory;
   OpenDialog.Filter:='PolyCad files (*.geo)|*.geo';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then
   begin
      if Owner.FileChanged then
      begin
         Answer:=MessageDlg(Userstring(103)+EOL+Userstring(104),mtConfirmation,[mbYes,mbNo,mbCancel],0);
         if Answer=mrCancel then
         begin
            OpenDialog.Destroy;
            exit;
         end;
         if Answer=mrYes then
         begin
            File_SaveAs;
            if Owner.FileChanged then
            begin
               // Apparently saving was not successfull, abort
               OpenDialog.Destroy;
               exit;
            end;
         end;
      end;
      PrevCursor:=Screen.Cursor;
      Screen.Cursor:=crHourglass;
      Strings:=TStringList.Create;

      try
         Strings.LoadFromFile(OpenDialog.FileName);
         // delete empty strings
         for I:=Strings.Count downto 1 do if Strings[I-1]='' then Strings.Delete(I-1);
         // count number of BSpline surfaces
         NSurfaces:=0;
         for I:=1 to strings.Count do if (pos('[TBSplineSurface]',Strings[I-1])<>0) or
                                         (pos('[TShipLines]',Strings[I-1])<>0) or
                                         (pos('[TYachtLines]',Strings[I-1])<>0) then
         begin
            Setlength(Indices,NSurfaces+1);
            Indices[NSurfaces]:=I-1;
            inc(NSurfaces);
         end;
         if NSurfaces>0 then
         begin
            CreateUndoObject(Userstring(118),True);
            Owner.Clear;
            Owner.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
            I:=1;
            Abort:=False;
            while (I<=NSurfaces) and (not Abort) do
            begin
               Index:=Indices[I-1];
               Str:=Strings[index];
               if (pos('[TYachtLines]',Strings[I-1])<>0) then
               begin
                  // Read loa
                  Str:=NextLine;
                  Owner.ProjectSettings.ProjectLength:=GetFloat(Str);
                  NextLine;
                  NextLine;
                  // read beam over all
                  Str:=NextLine;
                  Owner.ProjectSettings.ProjectBeam:=GetFloat(Str);
                  NextLine;
                  NextLine;
                  // Read draft
                  Str:=NextLine;
                  Owner.ProjectSettings.ProjectDraft:=GetFloat(Str);
                  Owner.ProjectSettings.FMainparticularsHasBeenset:=True;
                  for J:=1 to 12 do NextLine;
               end else if (pos('[TShipLines]',Strings[I-1])<>0) then
               begin
                  NextLine;
                  // Read length
                  Str:=NextLine;
                  Owner.ProjectSettings.ProjectLength:=GetFloat(Str);
                  // read beam
                  Str:=NextLine;
                  Owner.ProjectSettings.ProjectBeam:=GetFloat(Str);
                  // skip depth
                  NextLine;
                  // Read draft
                  Str:=NextLine;
                  Owner.ProjectSettings.ProjectDraft:=GetFloat(Str);
                  Owner.ProjectSettings.FMainparticularsHasBeenset:=True;
                  for J:=1 to 22 do NextLine;
               end;

               NextLine;            // skip OrderU=
               NextLine;            // skip OrderV=

               // Read number of columns
               Str:=NextLine;
               Cols:=GetInteger(Str);
               // Read number of rows
               Str:=NextLine;
               Rows:=GetInteger(Str);
               if (Cols>1) and (Rows>1) then
               begin
                  // Initialize points
                  Setlength(Points,Rows);
                  for J:=1 to Rows do
                  begin
                     Setlength(Points[J-1],Cols);
                     for K:=1 to Cols do Points[J-1][K-1]:=ZERO;
                  end;
                  for J:=1 to Cols do
                  begin
                     for K:=1 to Rows do
                     begin
                        Str:=NextLine;
                        if not abort then
                        begin
                           Str:=Trim(Str);
                           P.X:=0;
                           P.Y:=0;
                           P.Z:=0;
                           // X coordinate
                           Tmp:=NextParameter(Str);
                           if not abort then
                           begin
                              Val(Tmp,P.X,N);
                              if N<>0 then
                              begin
                                 MessageDlg(Userstring(119)+#32+IntToStr(I),mtError,[mbOk],0);
                                 Abort:=True;
                              end;
                           end;
                           if not Abort then
                           begin
                              Tmp:=NextParameter(Str);
                              if not abort then
                              begin
                                 Val(Tmp,P.Y,N);
                                 if N<>0 then
                                 begin
                                    MessageDlg(Userstring(120)+#32+IntToStr(I),mtError,[mbOk],0);
                                    Abort:=True;
                                 end;
                              end;
                           end;
                           if not Abort then
                           begin
                              // Z coordinate
                              Tmp:=NextParameter(Str);
                              if not abort then
                              begin
                                 Val(Tmp,P.Z,N);
                                 if N<>0 then
                                 begin
                                    MessageDlg(Userstring(121)+#32+IntToStr(I),mtError,[mbOk],0);
                                    Abort:=True;
                                 end;
                              end;
                           end;
                           Points[K-1][J-1]:=P;
                        end else break;
                     end;
                     if abort then break;
                  end;
                  if not Abort then Owner.Surface.ImportGrid(Points,Cols,Rows,nil);
               end;
               Inc(i);
            end;
            if not Abort then
            begin
               // Read contours;
               for I:=1 to Strings.Count do
               begin
                  if Pos('[TContours]',Strings[I-1])<>0 then
                  begin
                     Index:=I-1;
                     Str:=NextLine;
                     N:=GetInteger(Str);
                     if not abort then
                     begin
                        for J:=1 to N do
                        begin
                           Str:=NextLine;
                           if not abort then
                           begin
                              Str:=Trim(Str);
                              Tmp:=NextParameter(Str);
                              if not abort then
                              begin
                                 // 1=station, 2=buttock, 3=waterline
                                 K:=StrToInt(Tmp);
                              end else K:=0;
                              if not abort then
                              begin
                                 Val(Str,Value,N);
                                 if N<>0 then
                                 begin
                                    MessageDlg(Userstring(122),mtError,[mbOk],0);
                                    Abort:=True;
                                 end else
                                 begin
                                    Case K of
                                       1 : self.Intersection_Add(fiStation,Value);
                                       2 : if Value>=0 then self.Intersection_Add(fiButtock,Value);
                                       3 : self.Intersection_Add(fiWaterline,Value);
                                    end;
                                 end;
                              end;
                           end;
                           if abort then break;
                        end;
                     end;
                     break;
                  end;
               end;
               Owner.Precision:=fpMedium;
               Owner.FileName:=ChangeFileExt(Opendialog.FileName,'');
               Owner.Build:=False;
               Owner.RebuildModel;
               Owner.FileChanged:=true;
            end else MessageDlg(UserString(123),mtInformation,[mbOK],0);
         end else MessageDlg(UserString(124),mtInformation,[mbOk],0);
      finally
         Strings.Destroy;
         if Assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(self);
         Screen.Cursor:=PrevCursor;
      end;

   end;
   OpenDialog.Destroy;
end;{TFreeEdit.File_ImportPolycad}

// Load a VRML file
Procedure TFreeEdit.File_ImportVRML;
var OpenDialog : TOpenDialog;
    Answer     : Word;
    PrevCursor : TCursor;
begin
   OpenDialog:=TOpenDialog.Create(Owner);
   OpenDialog.InitialDir:=Owner.Preferences.ImportDirectory;
   OpenDialog.Filter:='VRML files (*.wrl)|*.wrl';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then
   begin
      if Owner.FileChanged then
      begin
         Answer:=MessageDlg(Userstring(103)+EOL+Userstring(104),mtConfirmation,[mbYes,mbNo,mbCancel],0);
         if Answer=mrCancel then
         begin
            OpenDialog.Destroy;
            exit;
         end;
         if Answer=mrYes then
         begin
            File_SaveAs;
            if Owner.FileChanged then
            begin
               // Apparently saving was not successfull, abort
               OpenDialog.Destroy;
               exit;
            end;
         end;
      end;
      PrevCursor:=Screen.Cursor;
      Screen.Cursor:=crHourglass;
      try
         CreateUndoObject(Userstring(125),True);
         Owner.Clear;
         Owner.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
         Owner.Surface.LoadVRMLFile(Opendialog.FileName);
         Owner.FileName:=ChangeFileExt(Opendialog.FileName,'');
         Owner.Build:=False;
         Owner.RebuildModel;
         Owner.FileChanged:=true;
      finally
         if Assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(self);
         Screen.Cursor:=PrevCursor;
      end;
   end;
   OpenDialog.Destroy;
end;{TFreeEdit.File_ImportVRML}

procedure TFreeEdit.File_Load;
var Answer     : word;
    OpenDialog : TOpenDialog;
begin
   OpenDialog:=TOpenDialog.Create(Owner);
   OpenDialog.InitialDir:=Owner.Preferences.OpenDirectory;
   OpenDialog.Filter:='FREE!ship files (*.fbm)|*.fbm';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then
   begin
      if Owner.FileChanged then
      begin
         Answer:=MessageDlg(Userstring(103)+EOL+Userstring(104),mtConfirmation,[mbYes,mbNo,mbCancel],0);
         if Answer=mrCancel then
         begin
            OpenDialog.Destroy;
            exit;
         end;
         if Answer=mrYes then
         begin
            File_SaveAs;
            if Owner.FileChanged then
            begin
               // Apparently saving was not successfull, abort
               OpenDialog.Destroy;
               exit;
            end;
         end;
      end;
      File_Load(Opendialog.FileName);   // Load everything into memory
   end;
   Opendialog.Destroy;
end;{TFreeEdit.File_Load}

procedure TFreeEdit.File_Load(filename:string);
var Source  : TFreeFileBuffer;
begin
   Source:=TFreeFileBuffer.Create;
   try
      Source.LoadFromFile(FileName);                // Load everything into memory
      Owner.Preferences.OpenDirectory:=ExtractFilePath(FileName);
      Owner.Filename:=ChangeFileExt(FileName,'.fbm');
      Owner.LoadBinary(Source);                    // Now read the information from memory
      Owner.Surface.Clearselection;                // Make sure no items are selected
      Owner.FSelectedFlowlines.Clear;
      Owner.FSelectedMarkers.Clear;
      Owner.Draw;
      Owner.FFilenameSet:=True;
      Owner.FStopAskingForFileVersion:=False;
   finally
      Source.Destroy;
      AddToRecentFiles(FileName);
      Undo_Clear;
   end;
   Owner.FileChanged:=False;
end;{TFreeEdit.File_Load}

// save as FREE!ship file without prompting for a filename (must already been set)
procedure TFreeEdit.File_Save;
var Backup     : string;
    Destination: TFreeFileBuffer;
    Str        : string;
    Answer     : word;
begin
   if not Owner.FilenameSet then File_SaveAs;
   if not Owner.FilenameSet then exit;

   if (Owner.FileVersion<CurrentVersion) and (not Owner.FStopAskingForFileVersion) then
   begin
      Str:=Userstring(126)+VersionString(Owner.FileVersion)+EOL+
           Userstring(127)+#32+VersionString(CurrentVersion)+ '?';
      Answer:=MessageDlg(Str,mtInformation,[mbYes,mbNo],0);
      if Answer=mrYes then Owner.FileVersion:=CurrentVersion
                      else Owner.FStopAskingForFileVersion:=True;
   end;

   Owner.FFilenameSet:=True;
   // Check if the file already exists
   if FileExists(Owner.Filename) then
   begin
      Backup:=ChangeFileExt(Owner.Filename,'.Bak');
      // First check for a backup, and delete when present
      if FileExists(Backup) then if not SysUtils.DeleteFile(Backup) then MessageDlg(Userstring(128),mtError,[mbOk],0);
      // Then create a backup of the old file
      if not RenameFile(Owner.Filename,Backup) then MessageDlg(Userstring(129),mtError,[mbOk],0);
   end;
   Destination:=TFreeFileBuffer.Create;
   Owner.SaveBinary(Destination);
   Destination.SaveToFile(Owner.Filename);
   Owner.Preferences.SaveDirectory:=ExtractFilePath(Owner.FileName);
   AddToRecentFiles(Owner.FileName);
   Destination.Destroy;
end;{TFreeEdit.File_Save}

procedure TFreeEdit.File_SaveAs;
var SaveDialog : TSaveDialog;
begin
   SaveDialog:=TSaveDialog.Create(Owner);
   SaveDialog.InitialDir:=Owner.Preferences.SaveDirectory;
   Savedialog.FileName:=ExtractFilename(Owner.Filename);
   SaveDialog.Filter:='FREE!ship files (*.fbm)|*.fbm';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then
   begin
      Owner.Preferences.SaveDirectory:=ExtractFilePath(SaveDialog.FileName);
      if CurrentVersion>Owner.FileVersion then Owner.FStopAskingForFileVersion:=False;
      Owner.Filename:=Savedialog.Filename;;
      Owner.FFilenameSet:=True;
      File_Save;
   end;
   SaveDialog.Destroy;
end;{TFreeEdit.File_SaveAs}

procedure TFreeEdit.Flowline_Add(Source:T2DCoordinate;View:TFreeviewType);
var Flowline : TFreeFlowline;
    Undo     : TFreeUndoObject;
begin
   Undo:=CreateUndoObject(Userstring(130),False);
   Flowline:=TFreeflowline.Create(Owner);
   Owner.FFlowLines.Add(Flowline);
   Flowline.FProjectionPoint:=Source;
   Flowline.FProjectionView:=View;
//   Flowline.FMethodNew:=True;
   Flowline.Rebuild;
   if Flowline.FFlowLine.NumberOfPoints>0 then
   begin
      Owner.FileChanged:=True;
      Undo.Accept;
      Owner.Redraw;
   end else
   begin
      Undo.Delete;
      Flowline.Delete;
   end;
end;{TFreeEdit.Flowline_Add}

procedure TFreeEdit.Geometry_AddCylinder;
var StartPoint    : T3DCoordinate;
    EndPoint      : T3DCoordinate;
    P1,P2         : T3DCoordinate;
    I,NPoints,Ne  : Integer;
    Points        : TFreeCoordinateGrid;
    Radius        : TFloatType;
    Angle         : TFloatType;
    Matrix        : TFreeMatrix;
    Inv,OrgPts    : TFreeMatrix;
    NewPts        : TFreeMatrix;
    Dialog        : TFreeCylinderDialog;
    NewLayer      : TFreeSubdivisionLayer;
begin
   Dialog:=TFreeCylinderDialog.Create(Owner);
   ShowTranslatedValues(Dialog);
   Dialog.StartPoint:=SetPoint(0.0,0.0,0.0);
   Dialog.EndPoint:=SetPoint(0.0,1.0,0.0);
   Dialog.Input7.Value:=1.0;
   Dialog.Input8.Value:=Dialog.Input8.Min+2;

   if Dialog.Execute(LengthStr(Owner.ProjectSettings.ProjectUnits)) then
   begin
      CreateUndoObject(Userstring(131),True);
      NewLayer:=Owner.Surface.AddNewLayer;
      StartPoint:=Dialog.StartPoint;
      EndPoint:=Dialog.EndPoint;
      Radius:=Dialog.Input7.Value;
      NPoints:=Dialog.Input8.AsInteger;
      Setlength(Points,2);
      setlength(Points[0],NPoints+1);
      setlength(Points[1],NPoints+1);

      // Prepare matrices
      Matrix:=TFreeMatrix.Create;
      Matrix.SetSize(NPoints+4,NPoints+4);
      Matrix.Fill(0.0);
      Matrix.Value[0,0]:=1.0;
      for I:=2 to NPoints+3 do
      begin
         Matrix.Value[I-1,I-2]:=1/6;
         Matrix.Value[I-1,I-1]:=2/3;
         Matrix.Value[I-1,I  ]:=1/6;
      end;
      Matrix.Value[NPoints+3,NPoints+3]:=1.0;
      // Invert matrix
      Inv:=Matrix.Invert;
      Matrix.Destroy;

      OrgPts:=TFreeMatrix.Create;
      OrgPts.SetSize(3,NPoints+4);
      for I:=1 to NPoints do
      begin
         Angle:=-((I-1)/NPoints)*2*Pi;
         P1.x:=StartPoint.x+Sin(Angle)*Radius;
         P1.y:=StartPoint.y+Cos(Angle)*Radius;
         P1.z:=StartPoint.z;
         P2:=RotatePointAroundVector(P1,StartPoint,Subtract(EndPoint,StartPoint));
         OrgPts.Value[I+1,0]:=P2.X;
         OrgPts.Value[I+1,1]:=P2.Y;
         OrgPts.Value[I+1,2]:=P2.Z;
      end;
      for I:=0 to 2 do
      begin
         OrgPts.Value[1,I]:=OrgPts.Value[NPoints+1,I];
         OrgPts.Value[0,I]:=OrgPts.Value[NPoints,I];
         OrgPts.Value[NPoints+2,I]:=OrgPts.Value[2,I];
         OrgPts.Value[NPoints+3,I]:=OrgPts.Value[3,I];
      end;
      // calculate new points
      NewPts:=Inv.Multiply(OrgPts);
      for I:=1 to NPoints do
      begin
         P1.X:=NewPts.Value[I+1,0];
         P1.Y:=NewPts.Value[I+1,1];
         P1.Z:=NewPts.Value[I+1,2];
         Points[0][I-1]:=P1;
         Points[1][I-1]:=SetPoint(P1.X+EndPoint.X-StartPoint.X,P1.Y+EndPoint.Y-StartPoint.Y,P1.Z+EndPoint.Z-StartPoint.Z);
      end;
      Points[0][NPoints]:=Points[0][0];
      Points[1][NPoints]:=Points[1][0];
      Inv.Destroy;
      OrgPts.Destroy;
      NewPts.Destroy;
      Ne:=Owner.Surface.NumberOfControlEdges;
      Owner.Surface.ImportGrid(Points,NPoints+1,2,NewLayer);
      for I:=Ne+1 to Owner.Surface.NumberOfControlEdges do Owner.Surface.ControlEdge[I-1].Crease:=False;
      Owner.Redraw;
   end;
   Dialog.Destroy;
end;{TFreeEdit.Geometry_AddCylinder}

// Creates and calculates a hydrostatics calculation
function TFreeEdit.Hydrostatics_Calculate(Draft,AngleOfHeel,Trim:TFloatType):TFreeHydrostaticCalc;
begin
   if not Owner.ProjectSettings.FMainparticularsHasBeenset then
   begin
      MessageDlg(UserString(196),mtError,[mbOk],0);
      Result:=nil;
   end else
   begin
      // Check model for inconsistencies
      if not Owner.ProjectSettings.DisableModelCheck then Model_Check(False);
      Result:=TFreeHydrostaticCalc.Create(Owner);
      Result.Trim:=Trim;
      Result.HeelingAngle:=AngleOfHeel;
      Result.Draft:=Draft;
      Result.Calculate;
      Result.ShowData(fhSingleCalculation);
   end;
end;{TFreeEdit.Hydrostatics_Calculate}

// Opens the dialog to calculate crosscurves
procedure TFreeEdit.Hydrostatics_Crosscurves;
var Dialog : TFreeCrosscurvesDialog;
begin
   if not Owner.ProjectSettings.FMainparticularsHasBeenset then
   begin
      MessageDlg(UserString(196),mtError,[mbOk],0);
   end else
   begin
      // Check model for inconsistencies
      if not Owner.ProjectSettings.DisableModelCheck then Model_Check(False);
      Dialog:=TFreeCrosscurvesDialog.Create(Owner);
      ShowTranslatedValues(Dialog);
      Dialog.SetDisplacements(Owner.ProjectSettings.FDisplacements,Owner.ProjectSettings.FNoDisplacements);
      Dialog.FreeNumInput2.Value:=Owner.ProjectSettings.FMinimumDisplacement;
      Dialog.FreeNumInput3.Value:=Owner.ProjectSettings.FMaximumDisplacement;
      Dialog.FreeNumInput4.Value:=Owner.ProjectSettings.FDisplIncrement;
      Dialog.CheckBox1.Checked:=Owner.ProjectSettings.FUseDisplIncrements;
      Dialog.SetHeelingAngles(Owner.ProjectSettings.FAngles,Owner.ProjectSettings.FNoAngles);
      if Dialog.Execute(Owner) then
      begin
         CreateUndoObject('crosscurves settings',true);
         Owner.ProjectSettings.FMinimumDisplacement:=Dialog.FreeNumInput2.Value;
         Owner.ProjectSettings.FMaximumDisplacement:=Dialog.FreeNumInput3.Value;;
         Owner.ProjectSettings.FDisplIncrement:=Dialog.FreeNumInput4.Value;
         Dialog.GetDisplacements(Owner.ProjectSettings.FDisplacements,Owner.ProjectSettings.FNoDisplacements);
         Owner.ProjectSettings.FUseDisplIncrements:=Dialog.CheckBox1.Checked;
         Dialog.GetHeelingAngles(Owner.ProjectSettings.FAngles,Owner.ProjectSettings.FNoAngles);
         
         Owner.FileChanged:=True;


      end;
      Dialog.Destroy;

   end;
end;{TFreeEdit.Hydrostatics_Crosscurves}

// Opens the hydrostatics dialog and calculates hydrostatic data for a range of inputdata
procedure TFreeEdit.Hydrostatics_Dialog;
var HydrostaticsForm : TFreeHydrostaticsForm;
begin
   HydrostaticsForm:=TFreeHydrostaticsForm.Create(Owner);
   ShowTranslatedValues(HydrostaticsForm);
   Hydrostaticsform.StartDraft:=Owner.ProjectSettings.Hydrostatics_Startdraft;
   Hydrostaticsform.EndDraft:=Owner.ProjectSettings.Hydrostatics_Enddraft;
   Hydrostaticsform.DraftStep:=Owner.ProjectSettings.Hydrostatics_DraftStep;
   Hydrostaticsform.Trim:=Owner.ProjectSettings.Hydrostatics_Trim;
   if TFreeHydrostaticsForm(HydrostaticsForm).Execute(Owner) then
   begin
      Owner.ProjectSettings.Hydrostatics_Startdraft:=HydrostaticsForm.StartDraft;
      Owner.ProjectSettings.Hydrostatics_Enddraft:=HydrostaticsForm.EndDraft;
      Owner.ProjectSettings.Hydrostatics_DraftStep:=HydrostaticsForm.DraftStep;
      Owner.ProjectSettings.Hydrostatics_Trim:=HydrostaticsForm.Trim;
   end;
end;{TFreeEdit.Hydrostatics_Dialog}

// Loads a bodyplane and tries to fit a surface to it
procedure TFreeEdit.ImportFrames;
type TMinMax   = record
                    MinZ,MaxZ:TFloatType;
                 end;
// Assumptions:
//    1. All stations have multiplicity of 1
//    2. All stations are defined from bottom to top
var OpenDialog    : TOpenDialog;
    I,J,K,Nr      : integer;
    Index         : integer;
    Frames        : TFasterList;
    FFile         : TextFile;
    NoStations    : integer;
    NoPoints      : integer;
    Spline        : TFreeSpline;
    NewSpline     : TFreeSpline;
    P             : T3DCoordinate;
    ValidStation  :Boolean;
    MinMaxData    : array of TMinMax;
    MinZ,MaxZ     : TFloatType;
    ControlPoints : array of array of TFreeSubdivisionControlPoint;
    P1,P2         : TFreeSubdivisionControlPoint;
    Edge          : TFreeSubdivisionControlEdge;
    Face          : TFreeSubdivisionControlFace;
    Points        : TFasterList;
    Marker        : TFreeMarker;
begin
   OpenDialog:=TOpenDialog.Create(Owner);
   OpenDialog.InitialDir:=ExtractFilepath(Application.ExeName);
   OpenDialog.Filter:='3D text file (*.Txt)|*.txt';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then
   begin
      Frames:=TFasterList.Create;
      Case OpenDialog.FilterIndex of
         1 :begin // 3D textfile containing stations, waterlines and buttocks
               AssignFile(FFile,Opendialog.FileName);
               {$I-}Reset(FFile);{$I+}
               if IOResult=0 then
               begin
                  K:=0;
                  Nr:=0;
                  inc(Nr);
                  Readln(FFile,NoStations);
                  for I:=1 to NoStations do
                  begin
                     inc(Nr);
                     readln(FFile);// Skip description of this line
                     inc(Nr);
                     readln(FFile,NoPoints);
                     Spline:=TFreeSpline.Create;
                     Spline.Capacity:=NoPoints;
                     ValidStation:=NoPoints>1;
                     for J:=1 to Nopoints do
                     begin
                        try
                           inc(Nr);
                           Read(FFile,P.X,P.Y,P.Z);
                           if not EOLN(FFile) then Readln(FFile,K) else
                           begin
                              K:=0;
                              Readln(FFile);
                           end;
                        except
                           Showmessage(Userstring(132)+#32+IntToStr(Nr));
                        end;
                        Spline.Add(P);
                        if J>1 then ValidStation:=abs(P.X-Spline.Point[0].X)<1e-4;
                        if (K=1) and (J<>1) and (J<>NoPoints) then Spline.Knuckle[J-1]:=True;
                     end;
                     if ValidStation then Frames.Add(Spline)
                                     else Spline.Destroy;
                  end;
                  CloseFile(FFile);
               end else MessageDlg(Userstring(132),mtError,[mbOk],0);
            end;
      end;
      if Frames.Count>1 then
      begin
         Owner.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
         CreateUndoObject(Userstring(133),True);
         Owner.Clear;
         Owner.Filename:=Opendialog.FileName;
         MinZ:=0.0;
         MaxZ:=0.0;
         // first sort the stations from aft to front
         for I:=1 to Frames.Count-1 do
            for J:=I+1 to Frames.count do if TFreeSpline(Frames[J-1]).Point[0].X<TFreeSpline(Frames[I-1]).Point[0].X then Frames.Exchange(I-1,J-1);
         // Determine the minimum and maximum Z values for each station
         // and the overall min/max z-coordinate
         Setlength(MinMaxData,Frames.Count);
         for I:=1 to Frames.Count do
         begin
            Spline:=Frames[I-1];
            MinMaxData[I-1].MinZ:=Spline.Point[0].Z;
            MinMaxData[I-1].MaxZ:=Spline.Point[Spline.NumberOfPoints-1].Z;
            if I=1 then
            begin
               MinZ:=Spline.Point[0].Z;
               MaxZ:=MinZ;
            end;
            if Spline.Point[0].Z<MinZ then MinZ:=Spline.Point[0].Z;
            if Spline.Point[Spline.NumberOfPoints-1].Z>MaxZ then MaxZ:=Spline.Point[Spline.NumberOfPoints-1].Z;
            Marker:=TFreeMarker.Create;
            Marker_Add(Marker);
            Marker.Capacity:=Spline.NumberOfPoints;
            for J:=1 to Spline.NumberOfPoints do
            begin
               Marker.Add(Spline.Point[J-1]);
               Marker.Knuckle[J-1]:=Spline.Knuckle[J-1];
            end;
         end;

         // extend all stations upwards and downwards to the min/max z-values
         for I:=1 to Frames.Count do
         begin
            Spline:=Frames[I-1];
            // extend downwards to Z=0
            if Spline.Point[0].Z>MinZ then
            begin
               P:=Spline.Point[0];
               P.Z:=MinZ;
               Spline.Insert(0,P);
               Spline.Knuckle[1]:=True;
            end;
            // extend upwards
            if Spline.Point[Spline.NumberOfPoints-1].Z<MaxZ then
            begin
               P:=Spline.Point[Spline.NumberOfPoints-1];
               P.Z:=MaxZ;
               Spline.Add(P);
               Spline.Knuckle[Spline.NumberOfPoints-2]:=True;
            end;
         end;

         NoPoints:=10;
         // resample all stations to a user defined number of points
         NoPoints:=StrToInt(InputBox('',Userstring(135)+':',IntToStr(NoPoints)));
         if NoPoints<5 then NoPoints:=5;
         Setlength(ControlPoints,Frames.Count);
         for I:=1 to Frames.Count do
         begin
            Spline:=Frames[I-1];
            NewSpline:=TFreeSpline.Create;
            NewSpline.Capacity:=NoPoints;
            for J:=1 to NoPoints do
            begin
               P:=Spline.Value((J-1)/(NoPoints-1));
               NewSpline.Add(P);
            end;
            // correct for any present knuckles
            for J:=1 to Spline.NumberOfPoints do if Spline.Knuckle[J-1] then
            begin
               Index:=0;
               // find the nearest point on resampled spline
               for K:=2 to NewSpline.NumberOfPoints-1 do if DistPP3D(Spline.Point[J-1],NewSpline.Point[K-1])<DistPP3D(Spline.Point[J-1],NewSpline.Point[index]) then Index:=K-1;
               // replace by the old coordinate
               NewSpline.Point[index]:=Spline.Point[J-1];
               NewSpline.Knuckle[index]:=True;
            end;

            // Delete the old station
            Spline.Destroy;
            // and replace by the resampled one
            Frames[I-1]:=NewSpline;
            // Add the controlpoints to the subdivision surface
            Setlength(ControlPoints[I-1],NewSpline.NumberOfPoints);
            for J:=1 to NewSpline.NumberOfPoints do ControlPoints[I-1][J-1]:=Owner.Surface.AddControlPoint(NewSpline.Point[J-1]);
         end;
         // Add the new controlfaces
         Points:=TfasterList.Create;
         For I:=2 to Frames.Count do
         begin
            for J:=2 to NoPoints do
            begin
               Points.Clear;
               Points.Add(ControlPoints[I-1][J-1]);
               Points.Add(ControlPoints[I-1][J-2]);
               Points.Add(ControlPoints[I-2][J-2]);
               Points.Add(ControlPoints[I-2][J-1]);
               Owner.Surface.AddControlFace(Points,True);
            end;
         end;

         Points.Clear;
         // Try to reconnect the contourline
         P1:=nil;
         P2:=nil;
         for I:=1 to Frames.Count do
         begin
            for J:=1 to NoPoints do if abs(ControlPoints[I-1][J-1].Coordinate.Z-MinMaxData[I-1].MinZ)<1e-5 then
            begin
               P2:=ControlPoints[I-1][J-1];
               if P2.Coordinate.Y<>0.0 then
               begin
                  // Force point to centerplane
                  P:=P2.Coordinate;
                  P.Y:=0;
                  P2.Coordinate:=P;
               end;
               break;
            end else Points.Add(ControlPoints[I-1][J-1]);// store to be deleted later
            if (P1<>nil) and (P2<>nil) then
            begin
               Edge:=Owner.Surface.EdgeExists(P1,P2) as TFreeSubdivisionControlEdge;
               if Edge<>nil then Edge.Crease:=True else
               begin
                  // Find out if P1 and P2 share the same controlface
                  for J:=1 to P1.NumberOfFaces do if P2.IndexOfFace(P1.Face[J-1])<>-1 then
                  begin
                     Face:=P1.Face[J-1] as TFreeSubdivisionControlFace;
                     Edge:=Face.InsertEdge(P1,P2);
                     if Edge<>nil then
                     begin
                        Edge.Crease:=True;
                     end;
                  end;
               end;
            end;
            P1:=P2;
            P2:=nil;
         end;

         // Try to reconnect the deckline
         P1:=nil;
         P2:=nil;
         for I:=1 to Frames.Count do
         begin
            for J:=1 to NoPoints do if abs(ControlPoints[I-1][J-1].Coordinate.Z-MinMaxData[I-1].MaxZ)<1e-5 then
            begin
               P2:=ControlPoints[I-1][J-1];
               K:=J+1;
               while K<=NoPoints do
               begin
                  Points.Add(ControlPoints[I-1][K-1]);
                  inc(K);
               end;
               break;
            end;
            if (P1<>nil) and (P2<>nil) then
            begin
               Edge:=Owner.Surface.EdgeExists(P1,P2) as TFreeSubdivisionControlEdge;
               if Edge<>nil then Edge.Crease:=True else
               begin
                  // Find out if P1 and P2 share the same controlface
                  for J:=1 to P1.NumberOfFaces do if P2.IndexOfFace(P1.Face[J-1])<>-1 then
                  begin
                     Face:=P1.Face[J-1] as TFreeSubdivisionControlFace;
                     Edge:=Face.InsertEdge(P1,P2);
                     if Edge<>nil then
                     begin
                        Edge.Crease:=True;
                     end;
                  end;
               end;
            end;
            P1:=P2;
            P2:=nil;
         end;
         // Delete all controlpoints beneath the contourline and above the deckline
         for J:=1 to Points.Count do
         begin
            P1:=Points[J-1];
            if Owner.Surface.PointExists(P1) then P1.Delete;
         end;
         for I:=1 to Owner.Surface.NumberOfControlPoints do if Owner.Surface.ControlPoint[I-1].NumberOfFaces=1 then Owner.Surface.ControlPoint[I-1].VertexType:=svCorner;
         Points.Destroy;
         Owner.FileChanged:=True;
      end;
      Owner.Draw;
      if Assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(self);
      // Destroy allocated stations
      for I:=1 to Frames.Count do
      begin
         Spline:=Frames[I-1];
         Spline.Destroy;
      end;
      Frames.Destroy;
   end;
   OpenDialog.Destroy;
end;{TFreeEdit.ImportFrames}

// Imports a number of curves and fits a surface;
procedure TFreeEdit.File_ImportSurface;
var OpenDialog    : TOpenDialog;
    I,J,Nr        : integer;
    Str           : string;
    FFile         : TextFile;
    Cols,Rows     : Integer;
    Spline        : TFreeSpline;
    NewSpline     : TFreeSpline;
    P             : T3DCoordinate;
    Points        : array of array of T3DCoordinate;
    ControlPoints : array of array of TFreeSubdivisionControlPoint;
    P1            : TFreeSubdivisionControlPoint;
    Curves        : TFasterList;
    LongCurves    : TFasterList;
    Pts           : TfasterList;
    Matrix        : TFreeMatrix;
    ColMatrix     : TFreeMatrix;
    RowMatrix     : TFreematrix;
    OrgPts        : TFreeMatrix;
    NewPts        : TFreeMatrix;
    UnitType      : TFreeUnitType;
    Marker        : TFreeMarker;
    PrevCursor    : TCursor;
begin
   OpenDialog:=TOpenDialog.Create(Owner);
   OpenDialog.InitialDir:=Owner.Preferences.ImportDirectory;
   OpenDialog.Filter:='3D text file (*.Txt)|*.txt';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then
   begin
      UnitType:=TFreeUnitType(0);
      Curves:=TFasterList.Create;
      Case OpenDialog.FilterIndex of
         1 :begin // 3D textfile containing a number of curves to be interpolated
               AssignFile(FFile,Opendialog.FileName);
               {$I-}Reset(FFile);{$I+}
               if IOResult=0 then
               begin
                  Nr:=0;
                  try
                     // first read unit information; 0=metric, 1=imperial
                     readln(FFile,I);
                     if I in [0,1] then UnitType:=TFreeUnitType(I)
                                   else MessageDlg(Userstring(108),mtError,[mbOk],0);
                     Spline:=TFreeSpline.Create;
                     repeat
                        Readln(FFile,Str);
                        repeat
                           I:=Pos(#9,Str);
                           if I<>0 then str[I]:=#32;
                        until I=0;
                        inc(Nr);
                        Str:=Trim(Uppercase(Str));
                        if (Str<>'') and (Str<>'EOF') then
                        begin
                           P.X:=ReadFloatFromStr(Nr,Str);
                           P.Y:=ReadFloatFromStr(Nr,Str);
                           P.Z:=ReadFloatFromStr(Nr,Str);
                           Spline.Add(P);
                           Str:=#32;
                        end else if Str='' then
                        begin
                           if Spline.NumberOfPoints>1 then Curves.Add(Spline)
                                                      else Spline.Destroy;
                           Spline:=TFreeSpline.Create;
                        end;
                     until (Str='EOF') or (EOF(FFile));
                     if Spline.NumberOfPoints>1 then Curves.Add(Spline)
                                                else Spline.Destroy;
                  except
                     MessageDlg(Userstring(132)+#32+IntToStr(Nr),mtError,[mbOk],0);
                  end;
                  CloseFile(FFile);
               end else MessageDlg(Userstring(132),mtError,[mbOk],0);
            end;
      end;
      if Curves.Count>1 then
      begin
         PrevCursor:=Screen.Cursor;
         Owner.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
         CreateUndoObject(Userstring(136),True);
         Owner.Clear;
         Owner.ProjectSettings.ProjectUnits:=UnitType;
         Owner.Filename:=Opendialog.FileName;
         try

            Cols:=Curves.Count;
            Cols:=StrToInt(InputBox('',Userstring(137)+':',IntToStr(Cols)));
            if Cols<3 then Cols:=3;

            Rows:=10;
            Rows:=StrToInt(InputBox('',Userstring(138)+':',IntToStr(Rows)));
            if Rows<3 then Rows:=3;

            // Build number of desired longitudinal curves
            LongCurves:=TFasterList.Create;
            for I:=1 to Rows do
            begin
               NewSpline:=TFreeSpline.Create;
               LongCurves.Add(NewSpline);
               Newspline.Capacity:=Curves.Count;
               for J:=1 to Curves.Count do
               begin
                  Spline:=Curves[J-1];
                  Newspline.Add(Spline.Value((I-1)/(Rows-1)));
               end;
            end;
            for I:=1 to Curves.Count do
            begin
               Spline:=Curves[I-1];
               Marker:=TFreeMarker.Create;
               Marker.Capacity:=Spline.NumberOfPoints;
               for J:=1 to Spline.NumberOfPoints do Marker.Add(Spline.Point[J-1]);
               Marker_Add(Marker);
               Spline.Destroy;
            end;
            Curves.Destroy;
   
            // build matrix for column interpolation
            Matrix:=TFreeMatrix.Create;
            Matrix.SetSize(Cols,Cols);
            Matrix.Fill(0.0);
            Matrix.Value[0,0]:=1.0;
            for I:=2 to Cols-1 do
            begin
               Matrix.Value[I-1,I-2]:=1/6;
               Matrix.Value[I-1,I-1]:=2/3;
               Matrix.Value[I-1,I  ]:=1/6;
            end;
            Matrix.Value[Cols-1,Cols-1]:=1.0;
            Colmatrix:=Matrix.Invert;
   
            Matrix.SetSize(Rows,Rows);
            Matrix.Fill(0.0);
            Matrix.Value[0,0]:=1.0;
            for I:=2 to Rows-1 do
            begin
               Matrix.Value[I-1,I-2]:=1/6;
               Matrix.Value[I-1,I-1]:=2/3;
               Matrix.Value[I-1,I  ]:=1/6;
            end;
            Matrix.Value[Rows-1,Rows-1]:=1.0;
            // Invert matrix
            Rowmatrix:=Matrix.Invert;
            Matrix.Destroy;
   
            // build initial point grid
            Setlength(Points,Rows);
            for I:=1 to Rows do
            begin
               setlength(Points[I-1],Cols);
               Spline:=LongCurves[I-1];
               OrgPts:=TFreeMatrix.Create;
               OrgPts.SetSize(3,Cols);
               for J:=1 to Cols do
               begin
                  P:=Spline.Value((J-1)/(Cols-1));
                  OrgPts.Value[J-1,0]:=P.X;
                  OrgPts.Value[J-1,1]:=P.Y;
                  OrgPts.Value[J-1,2]:=P.Z;
               end;
               NewPts:=ColMatrix.Multiply(OrgPts);
   
               for J:=1 to Cols do
               begin
                  P.X:=NewPts.Value[J-1,0];
                  P.Y:=NewPts.Value[J-1,1];
                  if (OrgPts.Value[J-1,1]>=0.0) and (P.Y<0.0) then P.Y:=0.0;
                  P.Z:=NewPts.Value[J-1,2];
                  Points[I-1][J-1]:=P;
               end;
   
               OrgPts.Destroy;
               NewPts.Destroy;
            end;
            ColMatrix.Destroy;
   
            // interpolate rows
            for I:=1 to Cols do
            begin
               OrgPts:=TFreeMatrix.Create;
               OrgPts.SetSize(3,Rows);
               for J:=1 to Rows do
               begin
                  P:=Points[J-1][I-1];
                  OrgPts.Value[J-1,0]:=P.X;
                  OrgPts.Value[J-1,1]:=P.Y;
                  OrgPts.Value[J-1,2]:=P.Z;
               end;
               NewPts:=RowMatrix.Multiply(OrgPts);
               for J:=1 to Rows do
               begin
                  P.X:=NewPts.Value[J-1,0];
                  P.Y:=NewPts.Value[J-1,1];
                  if (OrgPts.Value[J-1,1]>=0.0) and (P.Y<0.0) then P.Y:=0.0;
                  P.Z:=NewPts.Value[J-1,2];
                  Points[J-1][I-1]:=P;
               end;
               OrgPts.Destroy;
               NewPts.Destroy;
            end;
            RowMatrix.Destroy;
   
            // delete long. curves
            for I:=1 to LongCurves.Count do
            begin
               Spline:=LongCurves[I-1];
               Spline.Destroy;
            end;
            LongCurves.Destroy;
   
            // import actual surface
            Setlength(ControlPoints,Rows);
            for I:=1 to Rows do
            begin
               Setlength(ControlPoints[I-1],Cols);
               for J:=1 to Cols do
               begin
                  ControlPoints[I-1][J-1]:=TFreesubdivisionControlPoint.Create(Owner.Surface);
                  Owner.Surface.AddControlPoint(ControlPoints[I-1][J-1]);
                  ControlPoints[I-1][J-1].Coordinate:=Points[I-1][J-1];
                  //ControlPoints[I-1][J-1]:=Owner.Surface.AddControlPoint(Points[I-1][J-1]);
               end;
            end;
            Pts:=TFasterList.Create;
            for I:=2 to Rows do
            begin
               for J:=2 to Cols do
               begin
                  Pts.Clear;
                  P1:=ControlPoints[I-2][J-2];
                  Pts.Add(P1);
                  P1:=ControlPoints[I-2][J-1];
                  if Pts.IndexOf(P1)=-1 then Pts.Add(P1);
                  P1:=ControlPoints[I-1][J-1];
                  if Pts.IndexOf(P1)=-1 then Pts.Add(P1);
                  P1:=ControlPoints[I-1][J-2];
                  if Pts.IndexOf(P1)=-1 then Pts.Add(P1);
                  if Pts.Count>2 then Owner.Surface.AddControlFace(Pts,True);
               end;
            end;
            Pts.Destroy;
            Owner.FileChanged:=True;
         finally
            if Assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(self);
            Screen.Cursor:=PrevCursor;
         end;
      end;
      Owner.Build:=False;
      Owner.Precision:=fpMedium;
      Owner.Draw;
   end;
   OpenDialog.Destroy;
end;{TFreeEdit.ImportFrames}

procedure TFreeEdit.Intersection_AddToList(Intersection:TFreeIntersection);
var I,J        : integer;
    TargetList : TFasterList;
    Int1,Int2  : TFreeIntersection;
begin
   Case Intersection.IntersectionType of
      fiStation    : TargetList:=Owner.FStations;
      fiButtock    : TargetList:=Owner.FButtocks;
      fiWaterline  : TargetList:=Owner.FWaterlines;
      fiDiagonal   : TargetList:=Owner.FDiagonals;
      else TargetList:=nil;
   end;
   if TargetList<>nil then
   begin
      TargetList.Add(Intersection);
      // Now sort the list so that the distance is in ascending order
      for I:=1 to TargetList.Count-1 do
      begin
         Int1:=TargetList[I-1];
         for J:=I+1 to TargetList.Count do
         begin
            Int2:=Targetlist[J-1];
            if -Int2.FPlane.d<-Int1.FPlane.d then
            begin
               // swap the two intersections
               Targetlist.Exchange(I-1,J-1);
               Int1:=TargetList[I-1];
            end;
         end;
      end;
   end;
end;{TFreeEdit.Intersection_AddToList}

// Pops up the dialog in which to add or delete stations, buttocks and waterlines
procedure TFreeEdit.Intersection_Dialog;
var Dialog: TFreeIntersectionDialog;
begin
  Dialog:=Owner.FIntersectionDialog as TFreeIntersectionDialog;
  ShowTranslatedValues(Dialog);
  Dialog.Execute(Owner);
  Owner.FDesignHydrostatics.Calculated:=false;
  if Owner.Visibility.ShowHydrostaticData then Owner.Redraw;
end;{TFreeEdit.Intersection_Dialog}

// All connected patches surrounded by crease edges are grouped together into a new layer
procedure TFreeEdit.Layer_AutoGroup;
var ToDoList   : TList;
    DoneList   : TList;
    Current    : TList;
    I,J        : integer;
    Face,Face2 : TFreeSubdivisionControlFace;
    Layer      : TFreeSubdivisionLayer;
    SameLayer  : Boolean;

    procedure FindAttachedFaces(List:TList;Face:TFreeSubdivisionControlFace);
    var I,J    : integer;
        Index  : integer;
        P1,P2  : TFreeSubdivisionPoint;
        Edge   : TFreeSubdivisionEdge;
    begin
       P1:=Face.Point[Face.NumberOfPoints-1];
       for I:=1 to Face.NumberOfpoints do
       begin
          P2:=Face.Point[I-1];
          Edge:=Face.Owner.EdgeExists(P1,P2);
          if Edge<>nil then
          begin
             if not Edge.Crease then
             begin
                for J:=1 to Edge.NumberOfFaces do if Edge.Face[J-1]<>Face then
                begin
                   Index:=ToDoList.IndexOf(Edge.Face[J-1]);
                   if Index<>-1 then
                   begin
                      List.Add(Edge.Face[J-1]);
                      ToDoList.Delete(Index);
                      FindAttachedFaces(List,Edge.Face[J-1] as TFreeSubdivisionControlFace);
                   end;
                end;
             end;
          end;
          P1:=p2;
       end;
    end;{FindAttachedFaces}

begin
   ToDoList:=TList.Create;
   DoneList:=TList.Create;
   try
      if Owner.NumberOfSelectedControlFaces>0 then
      // Use only the selected ones
      begin
         ToDoList.Capacity:=ToDoList.Count+Owner.NumberOfSelectedControlFaces;
         for I:=1 to Owner.NumberOfSelectedControlFaces do
         begin
            Face:=Owner.SelectedControlFace[I-1];
            ToDoList.Add(Face);
         end;
      end else
      begin
         // use all visible faces
         for I:=1 to Owner.NumberOfLayers do
         begin
            Layer:=Owner.Layer[I-1];
            if Layer.Visible then
            begin
               ToDoList.Capacity:=ToDoList.Count+Layer.Count;
               for J:=1 to Layer.Count do
               begin
                  ToDoList.Add(Layer.Items[J-1]);
               end;
            end;
         end;
      end;
      if ToDoList.Count>0 then
      begin
         CreateUndoObject(Userstring(139),True);
         while ToDoList.Count>0 do
         begin
            Face:=ToDoList[ToDoList.Count-1];
            ToDoList.Delete(ToDoList.Count-1);
            Current:=TList.Create;
            Current.Add(Face);
            FindAttachedFaces(Current,Face);
            DoneList.Add(Current);
         end;
         // Assign all groups to different layers
         for I:=1 to DoneList.Count do
         begin
            Current:=DoneList[I-1];
            if Current.Count>0 then
            begin
               SameLayer:=True;
               // check if all selected faces currently belong to the same layer
               Face:=Current[0];
               For J:=2 to Current.Count do
               begin
                  Face2:=Current[J-1];
                  if Face2.Layer<>Face.Layer then SameLayer:=False;
               end;
               Layer:=nil;
               if SameLayer then
               begin
                  // yes, all faces belong to the same layer
                  if Current.Count=Face.Layer.Count then
                  begin
                     // apparently the same data is selected as in face.layer, do not change layer
                  end else
                  begin
                     // a subset of face.layer is selected, copy properties from that layer
                     Layer:=Owner.Surface.AddNewLayer;
                     Layer.AssignProperties(Face.Layer);
                  end;
               end else
               begin
                  // Faces belong to multiple layers,
                  Layer:=Layer_New;
                  Layer.Color:=RandomColor;
               end;
               if Layer<>nil then
               begin
                  for J:=1 to Current.Count do
                  begin
                     Face:=Current[J-1];
                     Face.Layer:=Layer;
                  end;
               end;
            end;
            Current.Destroy;
         end;
         Owner.ActiveLayer:=Owner.Layer[Owner.NumberOfLayers-1];
         // Delete empty layers
         Layer_DeleteEmpty(True);
         Owner.Redraw;
         Owner.FileChanged:=True;
      end;
   finally
      if assigned(Owner.OnChangeLayerData) then Owner.OnChangeLayerData(self);
      ToDoList.Destroy;
      DoneList.Destroy;
   end;
end;{TFreeEdit.Layer_AutoGroup}

// Develope all developable layers
procedure TFreeEdit.Layer_Develop;
var Layer   : TFreeSubdivisionLayer;
    Patch   : TFreeDevelopedPatch;
    Dlg     : TFreeExpanedplatesDialog;
    Plates  : TFasterList;
    I,J     : integer;
    Prev    : TCursor;
begin
   Prev:=Screen.Cursor;
   Screen.Cursor:=crHourGlass;
   Plates:=TFasterList.Create;
   try
      // perform a quiet test to check normal directions
      if not Owner.ProjectSettings.DisableModelCheck then Model_Check(False);
      for I:=1 to Owner.NumberOfLayers do
      begin
         Layer:=Owner.Layer[I-1];
         if Layer.Developable then
         begin
            Layer.Unroll(Plates);
         end;
      end;
      for I:=1 to Plates.Count do
      begin
         Patch:=Plates[I-1];
         for J:=1 to Owner.NumberofStations do Patch.IntersectPlane(Owner.Station[J-1].Plane,Owner.Station[J-1].Color);
         for J:=1 to Owner.NumberofWaterlines do Patch.IntersectPlane(Owner.Waterline[J-1].Plane,Owner.Waterline[J-1].Color);
         for J:=1 to Owner.NumberofButtocks do Patch.IntersectPlane(Owner.Buttock[J-1].Plane,Owner.Buttock[J-1].Color);
         for J:=1 to Owner.NumberofDiagonals do Patch.IntersectPlane(Owner.Diagonal[J-1].Plane,Owner.Diagonal[J-1].Color);
      end;
   finally
      Screen.Cursor:=Prev;
   end;
   if Plates.Count>0 then
   begin
      Dlg:=TFreeExpanedplatesDialog.Create(owner);
      ShowTranslatedValues(Dlg);
      Dlg.Execute(Owner,Plates);
      Dlg.Destroy;
   end;
   for I:=1 to Plates.Count do
   begin
      Patch:=plates[I-1];
      Patch.Destroy;
   end;
   Plates.Destroy;
end;{TFreeEdit.Layer_Develop}

// Delete all layers that are empty from the model
procedure TFreeEdit.Layer_DeleteEmpty;
var I,N   : integer;
    Undo  : TFreeUndoObject;
begin
   N:=0;
   if Quiet then Undo:=nil
            else Undo:=CreateUndoObject(Userstring(140),false);
   for I:=Owner.NumberOfLayers downto 1 do if (Owner.Layer[I-1].Count=0) and (Owner.NumberOfLayers>1) then
   begin
      Owner.Layer[I-1].Delete;
      inc(N);
      Owner.FileChanged:=True;
   end;
   if Owner.ActiveLayer=nil then Owner.ActiveLayer:=Owner.Layer[Owner.NumberOfLayers-1]
                            else Owner.ActiveLayer:=Owner.ActiveLayer;
   if (N>0) and (not Quiet) then
   begin
      Undo.Accept;
      ShowMessage(IntToStr(N)+#32+Userstring(141)+'.');
   end;
   if (N=0) and (Undo<>nil) then Undo.Delete;
end;{TFreeEdit.Layer_DeleteEmpty}

// Show layer dialog window
procedure TFreeEdit.Layer_Dialog;
var LayerDialog : TFreeLayerDialog;
begin
   LayerDialog:=TFreeLayerDialog.Create(Owner);
   ShowTranslatedValues(LayerDialog);
   LayerDialog.Execute(Owner);
   LayerDialog.Free;
end;{TFreeEdit.Layer_Dialog}

function TFreeEdit.Layer_New:TFreeSubdivisionLayer;
begin
   CreateUndoObject(Userstring(142),True);
   Result:=Owner.Surface.AddNewLayer;
   Result.Color:=Owner.Preferences.LayerColor;
   Owner.FileChanged:=True;
end;{TFreeEdit.Layer_New}

// Adds a marker to the list with markers
procedure TFreeEdit.Marker_Add(Marker:TFreeMarker);
begin
   Owner.FMarkers.Add(Marker);
   Marker.FOwner:=Owner;
end;{TFreeEdit.Marker_Add}

// Delete all markers from the model
procedure TFreeEdit.Marker_Delete;
var I:Integer;
begin
   if MessageDlg(Userstring(143),mtConfirmation,[mbYes,mbNo],0)=mrYes then
   begin
      CreateUndoObject(Userstring(144),True);
      for I:=1 to Owner.NumberofMarkers do Owner.Marker[I-1].Destroy;
      Owner.FMarkers.Clear;
      Owner.FileChanged:=True;
      for I:=1 to Owner.NumberOfViewports do if Owner.Viewport[I-1].Zoom=1.0 then Owner.Viewport[I-1].ZoomExtents
                                                                             else Owner.Viewport[I-1].Refresh;
   end;
end;{TFreeEdit.Marker_Delete}

// Import markers from a textfile
procedure TFreeEdit.Marker_Import;
var OpenDialog : TOpenDialog;
    Str        : string;
    I          : integer;
    LineNr     : Integer;
    P          : T3DCoordinate;
    FFile      : TextFile;
    Markers    : TFasterList;
    Marker     : TFreeMarker;
    Answer     : word;

    procedure Import(Markers:TFasterList);
    var I      : Integer;
        Marker : TFreeMarker;
    begin
      for I:=1 to Markers.Count do
      begin
         Marker:=Markers[I-1];
         Marker_Add(Marker);
      end;
      Owner.FileChanged:=True;
      Owner.Visibility.ShowMarkers:=True;
      for I:=1 to Owner.NumberOfViewports do if Owner.Viewport[I-1].Zoom=1.0 then Owner.Viewport[I-1].ZoomExtents
                                                                             else Owner.Viewport[I-1].Refresh;
      Owner.Redraw;
    end;{import}

begin
   OpenDialog:=TOpenDialog.Create(Owner);
   OpenDialog.InitialDir:=Owner.Preferences.ImportDirectory;
   OpenDialog.Filter:='Text files (*.txt)|*.txt';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then
   begin
      assignFile(FFile,ChangeFileExt(Opendialog.FileName,'.txt'));
      {$I-}Reset(FFile);{$I+}
      if IOResult=0 then
      begin
         Owner.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
         LineNr:=1;
         // skip the first line of the file
         readln(FFile);
         Markers:=TFasterList.Create;
         try
            try
               Marker:=TFreeMarker.Create;
               repeat
                  Readln(FFile,Str);
                  repeat
                     i:=Pos(#9,Str);
                     if I<>0 then str[I]:=#32;
                  until I=0;
                  inc(LineNr);
                  Str:=Trim(Uppercase(Str));
                  if (Str<>'') and (Str<>'EOF') then
                  begin
                     P.X:=ReadFloatFromStr(LineNr,Str);
                     P.Y:=ReadFloatFromStr(LineNr,Str);
                     P.Z:=ReadFloatFromStr(LineNr,Str);
                     Marker.Add(P);
                     Str:=#32;
                  end else if Str='' then
                  begin
                     if Marker.NumberOfPoints>1 then Markers.Add(Marker)
                                                else Marker.Destroy;
                     Marker:=TFreeMarker.Create;
                  end;
               until (Str='EOF') or (EOF(FFile));
               if Marker.NumberOfPoints>1 then Markers.Add(Marker)
                                          else Marker.Destroy;
            except
               MessageDlg(Userstring(132)+#32+IntToStr(LineNr),mtError,[mbOk],0);
            end;
         finally
            CloseFile(FFile);
         end;
         if Markers.Count>0 then
         begin
            if Owner.NumberofMarkers>0 then
            begin
               Answer:=MessageDlg(Userstring(145),mtConfirmation,[mbYes,mbNo,mbCancel],0);
               if Answer<>mrCancel then
               begin
                  CreateUndoObject(Userstring(146),True);
                  if Answer=mrYes then
                  begin
                     for I:=1 to Owner.NumberofMarkers do Owner.Marker[I-1].Destroy;
                     Owner.FMarkers.Clear;
                  end;
                  Import(Markers);
               end else
               begin
                  for I:=1 to Markers.Count do
                  begin
                     Marker:=Markers[I-1];
                     Marker.Destroy;
                  end;
               end;
            end else
            begin
               CreateUndoObject(Userstring(146),True);
               Import(Markers);
            end;
         end else MessageDlg(Userstring(147),mtInformation	,[mbOk],0);
         Markers.Destroy;
      end else
      begin
         MessageDlg(Userstring(106),mtError,[mbOk],0);
      end;
   end;
   OpenDialog.Destroy;
end;{TFreeEdit.Marker_Import}

// Checks the surface for inconsistent normal directions and leaks
procedure TFreeEdit.Model_Check(ShowResult:Boolean);
const EdgeError = 1e-4;
var I,J           : integer;
    Point,Pt      : TFreeSubdivisionPoint;
    Face          : TFreeSubdivisionFace;
    Edge1,Edge2   : TFreeSubdivisionControlEdge;
    CtrlFace      : TFreeSubdivisionControlFace;
    CtrlPoint     : TFreeSubdivisionControlPoint;
    AllFaces      : TFasterList;
    NewGroup      : TFasterList;
    DoubleEdges   : TFasterList;
    Points        : TFasterList;
    Changed       : Boolean;
    InvertedFaces : integer;
    Inconsistent  : integer;
    NonManifold   : integer;
    DblEdges      : Integer;
    Str           : Widestring;
    Undo          : TFreeUndoObject;
    Leaks         : TFasterList;
    Swap          : Boolean;
    NewLayer      : TFreeSubdivisionLayer;
    Normal,Tmp    : T3DCoordinate;

    procedure FindConnectedFaces(DoneList,ToDoList:TFasterList);
    var I,J,K,Ind : integer;
        P1,P2     : TFreeSubdivisionPoint;
        Edge      : TFreeSubdivisionEdge;
        F1,F2     : TFreeSubdivisionFace;
    begin
       I:=1;
       while I<=DoneList.Count do
       begin
          F1:=DoneList[I-1];
          P1:=F1.Point[F1.NumberOfPoints-1];
          for J:=1 to F1.NumberOfPoints do
          begin
             P2:=F1.Point[J-1];
             Edge:=Owner.Surface.EdgeExists(P1,P2);
             if Edge<>nil then if Edge.NumberOfFaces>1 then
             begin
                for K:=1 to Edge.NumberOfFaces do if Edge.Face[K-1]<>F1 then
                begin
                   F2:=Edge.Face[K-1];
                   Ind:=ToDoList.SortedIndexOf(F2);
                   if Ind<>-1 then
                   begin
                      // This face is connected to the current, but not present in the
                      // done-list.
                      DoneList.Add(F2);
                      ToDoList.Delete(Ind);
                      // Also perform a check to determine if F2 is oriented in
                      // the same way as F1 (clockwise or counterclockwise
                      Ind:=F2.IndexOfPoint(P2);
                      Ind:=(Ind+1) mod F2.NumberOfPoints; // select the next index
                      if F2.Point[ind]=P1 then
                      begin
                         // Direction is OK, do nothing
                      end else
                      begin
                         // direction is not ok, invert points
                         F2.FlipNormal;
                         inc(Inconsistent);
                      end;
                   end;
                end;
             end;
             P1:=p2;
          end;
          inc(I);
       end;
    end;// FindConnectedFaces

begin
   Undo:=self.CreateUndoObject(Userstring(148),false);
   Changed:=False;
   InvertedFaces:=0;
   Inconsistent:=0;
   NonManifold:=0;
   DblEdges:=0;
   // if ShowResult=false a quiet test is done, only the direction of facenormals is checked and fixed
   if ShowResult then
   begin
      // Find double edges
      DoubleEdges:=TFasterList.Create;
      for I:=1 to Owner.Surface.NumberOfControlEdges do
      begin
         Edge1:=Owner.Surface.ControlEdge[I-1];
         if Edge1.NumberOfFaces=1 then if DoubleEdges.SortedIndexOf(Edge1)=-1 then
         begin
            for J:=1 to Edge1.StartPoint.NumberOfEdges do
            begin
               Edge2:=Edge1.StartPoint.Edge[J-1] as TFreeSubdivisionControlEdge;
               if (Edge1<>Edge2) and (Edge2.NumberOfFaces=1) then
               begin
                  if ((DistPP3D(Edge1.StartPoint.Coordinate,Edge2.StartPoint.Coordinate)<EdgeError) and (DistPP3D(Edge1.EndPoint.Coordinate,Edge2.EndPoint.Coordinate)<EdgeError)) or
                     ((DistPP3D(Edge1.StartPoint.Coordinate,Edge2.EndPoint.Coordinate)<EdgeError) and (DistPP3D(Edge1.EndPoint.Coordinate,Edge2.StartPoint.Coordinate)<EdgeError)) then if DoubleEdges.SortedIndexOf(Edge2)=-1 then DoubleEdges.AddSortedObject(Edge1,Edge2);
               end;
            end;
         end;
      end;
      Points:=TFasterList.Create;
      for I:=1 to DoubleEdges.Count do
      begin
         Edge1:=DoubleEdges[I-1];
         Edge2:=DoubleEdges.Objects[I-1];
         if (Owner.Surface.ControlEdges.IndexOf(Edge1)<>-1) and (Owner.Surface.ControlEdges.IndexOf(Edge2)<>-1) then
         begin
            // remove the face connected to edge2 and rebuild it
            // by connecting it to edge1
            Ctrlface:=Edge2.Face[0] as TFreeSubdivisionControlFace;
            Points.Clear;
            for J:=1 to CtrlFace.NumberOfpoints do
            begin
               Point:=CtrlFace.Point[J-1];
               if Point=Edge2.StartPoint then
               begin
                  if DistPP3D(Edge2.StartPoint.Coordinate,Edge1.StartPoint.Coordinate)<EdgeError then
                  begin
                     if Points.IndexOf(Edge1.StartPoint)=-1 then points.Add(Edge1.StartPoint);
                  end else if DistPP3D(Edge2.StartPoint.Coordinate,Edge1.EndPoint.Coordinate)<EdgeError then
                  begin
                     if Points.IndexOf(Edge1.EndPoint)=-1 then points.Add(Edge1.EndPoint);
                  end;
               end else if Point=Edge2.EndPoint then
               begin
                  if DistPP3D(Edge2.EndPoint.Coordinate,Edge1.StartPoint.Coordinate)<EdgeError then
                  begin
                     if Points.IndexOf(Edge1.StartPoint)=-1 then points.Add(Edge1.StartPoint);
                  end else if DistPP3D(Edge2.EndPoint.Coordinate,Edge1.EndPoint.Coordinate)<EdgeError then
                  begin
                     if Points.IndexOf(Edge1.EndPoint)=-1 then points.Add(Edge1.EndPoint);
                  end;
               end else if Points.IndexOf(Point)=-1 then Points.Add(Point);
            end;
            if Points.Count>2 then
            begin
               NewLayer:=Ctrlface.Layer;
               Owner.Surface.AddControlFace(Points,False,NewLayer);
               CtrlFace.Delete;
               Changed:=True;
               inc(DblEdges);
            end;
         end;
      end;
      DoubleEdges.Destroy;
      Points.Destroy;
   end;

   // Check for correct normal direction (outward)
   // First assemble all controlfaces and extract
   // isolated groups (not physically connected)
   AllFaces:=TFasterList.Create;
   AllFaces.Capacity:=Owner.Surface.NumberOfControlFaces;
   for I:=1 to Owner.Surface.NumberOfControlFaces do AllFaces.Add(Owner.Surface.ControlFace[I-1]);
   AllFaces.Sort; // Sort list for faster object search

   Leaks:=TFasterList.Create;
   // assemble leaks
   for I:=1 to Owner.Surface.NumberOfControlPoints do
   begin
      CtrlPoint:=Owner.Surface.ControlPoint[I-1];
      if CtrlPoint.IsLeak then Leaks.Add(CtrlPoint);
   end;
   // sort leaks in ascending z-coordinate
   for I:=1 to Leaks.Count-1 do
   begin
      for J:=I+1 to Leaks.Count do
      begin
         Point:=Leaks[I-1];
         Pt:=Leaks[J-1];
         Swap:=False;
         if Pt.Coordinate.Z<Point.Coordinate.Z then Swap:=True;
         if (abs(Pt.Coordinate.Z-Point.Coordinate.Z)<1e-6) and (Pt.Coordinate.X<Point.Coordinate.X) then Swap:=True;
         if (abs(Pt.Coordinate.Z-Point.Coordinate.Z)<1e-6) and (abs(Pt.Coordinate.X-Point.Coordinate.X)<1e-6) and (Pt.Coordinate.Y<Point.Coordinate.Y) then Swap:=True;
         if Swap then Leaks.Exchange(I-1,J-1);
      end;
   end;

   for I:=1 to Owner.Surface.NumberOfControlEdges do if Owner.Surface.ControlEdge[I-1].NumberOfFaces>2 then inc(NonManifold);
   if AllFaces.Count>0 then
   begin
      NewGroup:=TFasterList.Create;
      while AllFaces.Count>0 do
      begin
         Face:=AllFaces[AllFaces.Count-1];
         AllFaces.Delete(AllFaces.Count-1);
         NewGroup.Clear;
         NewGroup.Capacity:=AllFaces.Count;
         NewGroup.Add(Face);
         // use the first face as seed for the following procedure
         FindConnectedFaces(NewGroup,AllFaces);
         NewGroup.Sort;

         // find the lowest point of this group of faces
         Point:=nil;
         for I:=1 to NewGroup.Count do
         begin
            Face:=NewGroup[I-1];
            for j:=1 to Face.NumberOfpoints do
            begin
               Pt:=Face.Point[J-1];
               if Point=nil then Point:=Pt
                            else if Pt.Coordinate.Z<Point.Coordinate.Z then Point:=Pt;
            end;
         end;
         if Point<>nil then
         begin
            // select the a face connected to this point and also present in the
            // newgroup-list with faces and with the most vertical normal of all canditates
            Face:=nil;
            for I:=1 to Point.NumberOfFaces do if NewGroup.SortedIndexOf(Point.Face[I-1])<>-1 then
            begin
               if Face=nil then
               begin
                  Face:=Point.Face[I-1];
                  normal:=Face.FaceNormal;
               end else
               begin
                  Tmp:=Point.Face[I-1].FaceNormal;
                  if abs(Tmp.Z)>abs(Normal.Z) then
                  begin
                     Face:=Point.Face[I-1];
                     normal:=Face.FaceNormal;
                  end;
               end;
            end;
            if Face<>nil then
            begin
               if Normal.Z>0.0 then
               begin
                  // normal points upward, all faces in this group must be inverted
                  for I:=1 to NewGroup.Count do
                  begin
                     Face:=NewGroup[I-1];
                     Face.FlipNormal;
                  end;
                  Changed:=True;
                  inc(InvertedFaces,NewGroup.Count);
               end;
            end;
         end;
      end;
      NewGroup.Destroy;
      if (Leaks.Count>0) and (ShowResult) then
      begin
         Str:=Userstring(149)+#32+IntToStr(Leaks.Count)+#32+Userstring(150)+'.';
         if Leaks.Count>10 then Str:=Str+EOL+Userstring(151)+':';
         Str:=Str+EOL;
         for I:=1 to Leaks.Count do
         begin
            Point:=Leaks[I-1];
            Str:=Str+EOL+FloatToStrF(Point.Coordinate.X,ffFixed,7,3)+', '+FloatToStrF(Point.Coordinate.Y,ffFixed,7,3)+', '+FloatToStrF(Point.Coordinate.Z,ffFixed,7,3);
            if I=10 then break;
         end;
         MessageDlg(Str,mtWarning,[mbOk],0);
      end;

      if (Changed) or (Inconsistent>0) or (NonManifold>0) or (DblEdges>0) then
      begin
         Undo.Accept;
         Owner.Build:=False;
         Owner.Redraw;
         Owner.FileChanged:=True;
         if ShowResult then
         begin
            Str:=Userstring(152)+':';
            if DblEdges>0 then Str:=Str+EOL+IntToStr(DblEdges)+#32+UserString(158)+'.';
            if Inconsistent>0 then Str:=Str+EOL+IntToStr(Inconsistent)+#32+Userstring(153)+'.';
            if InvertedFaces>0 then Str:=Str+EOL+IntToStr(InvertedFaces)+#32+Userstring(154)+'.';
            if NonManifold>0 then
            begin
               Str:=Str+EOL+IntToStr(NonManifold)+#32+Userstring(155);
            end;
            MessageDlg(Str,mtInformation,[mbOk],0);
            if assigned(Owner.FOnUpdateGeometryInfo) then Owner.FOnUpdateGeometryInfo(self);
         end;
      end else
      begin
         Undo.Delete;
         if (ShowResult) and (Leaks.Count=0) then ShowMessage(Userstring(156));
      end;
      Leaks.Destroy;
   end;
   AllFaces.Destroy;
end;{TFreeEdit.Model_Check}

// Start a new model (with a predefined surface)
// returns true if a new model has indeed been created
function TFreeEdit.Model_New:Boolean;
var Answer     : word;
    L,B,D      : TFloatType;
    I,J        : integer;
    Cols,Rows  : integer;
    P          : T3DCoordinate;
    Default    : array[0..6,0..4] of T3DCoordinate; // Default ship has 7 columns of 5 points(or rows)
    Spline1    : TFreeSpline;
    Spline2    : TFreeSpline;
    TrvSplines : TFasterList;
    Pts        : array of array of TFreeSubdivisionControlPoint;
    StemPoint  : TFreeSubdivisionControlPoint;
    FreeNewModelDialog : TFreeNewModelDialog;

    function Point3D(X,Y,Z:TFloattype):T3DCoordinate;
    begin
       Result.X:=X;
       Result.Y:=Y;
       Result.Z:=Z;
    end;{Point3D}

begin
   Result:=False;
   if Owner.FileChanged then
   begin
      Answer:=MessageDlg(Userstring(103)+EOL+Userstring(104),mtConfirmation,[mbYes,mbNo,mbCancel],0);
      if Answer=mrCancel then exit;
      if Answer=mrYes then
      begin
         Owner.Edit.File_SaveAs;
         if Owner.FileChanged then
         begin
            // Apparently saving was not successfull, abort
            exit;
         end;
      end;
   end;
   FreeNewModelDialog:=TFreeNewModelDialog.Create(Owner);
   ShowTranslatedValues(FreeNewModelDialog);
   if FreeNewModelDialog.Execute then
   begin
      CreateUndoObject(Userstring(157),True);
      Cols:=FreeNewModelDialog.NCols-1;
      Rows:=FreeNewModelDialog.NRows-1;
      L:=FreeNewModelDialog.Length;
      B:=FreeNewModelDialog.Breadth;
      D:=FreeNewModelDialog.Draft;
      // station 0, stern
      Default[0,0]:=Point3D(0.00000,0.00000,1.56754);
      Default[0,1]:=Point3D(0.00000,0.05280,1.59170);
      Default[0,2]:=Point3D(0.00000,0.22171,1.77284);
      Default[0,3]:=Point3D(0.00000,0.28506,2.64108);
      Default[0,4]:=Point3D(0.00000,0.29135,3.48932);
      // station 1
      Default[1,0]:=Point3D(0.20880,0.00000,0.49656);
      Default[1,1]:=Point3D(0.20881,0.18796,0.53622);
      Default[1,2]:=Point3D(0.20880,0.33700,0.97840);
      Default[1,3]:=Point3D(0.20880,0.45607,2.05422);
      Default[1,4]:=Point3D(0.20882,0.47184,3.44280);
      // station 2
      Default[2,0]:=Point3D(0.41765,0.00000,0.00000);
      Default[2,1]:=Point3D(0.41765,0.23565,0.07524);
      Default[2,2]:=Point3D(0.41765,0.41555,0.67735);
      Default[2,3]:=Point3D(0.41765,0.49421,1.91004);
      Default[2,4]:=Point3D(0.41737,0.51468,3.45474);
      // station 3
      Default[3,0]:=Point3D(0.58471,0.00000,0.00000);
      Default[3,1]:=Point3D(0.58472,0.24072,0.02507);
      Default[3,2]:=Point3D(0.58472,0.39528,0.71080);
      Default[3,3]:=Point3D(0.58488,0.45356,2.04881);
      Default[3,4]:=Point3D(0.58472,0.46756,3.54662);
      // station 4
      Default[4,0]:=Point3D(0.75179,0.00000,0.28284);
      Default[4,1]:=Point3D(0.75178,0.13715,0.44098);
      Default[4,2]:=Point3D(0.75179,0.20950,0.87760);
      Default[4,3]:=Point3D(0.75179,0.30538,2.38232);
      Default[4,4]:=Point3D(0.75177,0.34473,3.67786);
      // station 5
      Default[5,0]:=Point3D(0.90672,0.00000,0.81860);
      Default[5,1]:=Point3D(0.90681,0.01887,0.98650);
      Default[5,2]:=Point3D(0.90658,0.04671,1.29873);
      Default[5,3]:=Point3D(0.90637,0.11195,2.83107);
      Default[5,4]:=Point3D(0.90672,0.14523,3.81697);
      // station 6 , stem
      Default[6,0]:=Point3D(0.91580,0.00000,0.85643);
      Default[6,1]:=Point3D(0.92562,0.00000,1.17444);
      Default[6,2]:=Point3D(0.93387,0.00000,1.44618);
      Default[6,3]:=Point3D(0.97668,0.00000,3.03482);
      Default[6,4]:=Point3D(1.00000,0.00000,3.91366);
      Owner.Clear;

      Owner.ProjectSettings.ProjectUnits:=TFreeUnitType(FreeNewModelDialog.ComboBox1.ItemIndex);
      Owner.ProjectSettings.ProjectLength:=L;
      Owner.ProjectSettings.ProjectBeam:=B;
      Owner.ProjectSettings.ProjectDraft:=D;

      TrvSplines:=TFasterList.Create;
      StemPoint:=nil;
      // First create tmp. splines in transverse direction
      for I:=0 to 6 do
      begin
         Spline1:=TFreeSpline.Create;
         for J:=0 to 4 do
         begin
            P:=Default[I,J];
            P.X:=P.X*L;
            P.Y:=P.Y*B;
            P.Z:=P.Z*D;
            Spline1.Add(P);
         end;
         TrvSplines.Add(Spline1);
      end;
      // now create tmp. splines in longitudinal direction
      Setlength(Pts,Rows+1);
      for I:=0 to rows do
      begin
         Setlength(Pts[I],Cols+1);
         Spline2:=TFreeSpline.Create;
         for j:=0 to TrvSplines.Count-1 do
         begin
            Spline1:=TrvSplines[J];
            P:=Spline1.Value(I/Rows);
            Spline2.Add(P);
         end;
         // now calculate all points on the longitudinal spline and send it to the surface
         for J:=0 to Cols do
         begin
            P:=Spline2.Value(J/Cols);
            Pts[I,J]:=TFreeSubdivisionControlPoint.Create(Owner.Surface);
            Owner.Surface.AddControlPoint(Pts[I,J]);
            Pts[I,J].Coordinate:=P;
            if (I=0) and (J=Cols) then
            begin
               StemPoint:=Pts[I,J];
            end;
         end;
         Spline2.Destroy;
      end;
      // Destroy tmp splines
      for I:=1 to TrvSplines.Count do
      begin
         Spline1:=TrvSplines[I-1];
         Spline1.Destroy;
      end;
      TrvSplines.Clear;
      // finally create the controlfaces over the newly calculated points
      for I:=1 to Rows do
      begin
         for J:=1 to cols do
         begin
            TrvSplines.Clear;
            Trvsplines.Add(Pts[I,J-1]);
            Trvsplines.Add(Pts[I,J]);
            Trvsplines.Add(Pts[I-1,J]);
            Trvsplines.Add(Pts[I-1,J-1]);
            Owner.Surface.AddControlFace(Trvsplines,True);
         end;
      end;
      Owner.Precision:=fpMedium;
      Owner.Surface.Initialize(1,1,1);
      // Collapse stempoint to mage the grid irregular in order to demonstrate subdivision-surface capabilities
      if StemPoint<>nil then if StemPoint.VertexType=svCorner then stempoint.VertexType:=svCrease;
      Owner.Build:=False;

      // Add 21 stations
      for I:=0 to 20 do Intersection_Add(fiStation,I/20*(Owner.Surface.Max.X-Owner.Surface.Min.X));
      // Add 7 buttocks
      for I:=1 to 6 do Intersection_Add(fiButtock,I/7*(Owner.Surface.Max.Y-Owner.Surface.Min.Y));
      // Add 11 waterlines
      for I:=0 to 10 do Intersection_Add(fiWaterline,I/10*(Owner.Surface.Max.Z-Owner.Surface.Min.Z));

      Owner.draw;
      Owner.FileChanged:=True;
      if Assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(self);
      Result:=true;
      TrvSplines.Destroy;
   end;
   FreeNewModelDialog.Destroy;
end;{TFreeEdit.Model_New}

// Affine hullform transformation according to Lackenby
procedure TFreeEdit.Model_LackenbyTransformation;
var Dialog     : TFreeLackenbyDialog;
    Undo       : TFreeUndoObject;
    UndoIndex  : Integer;
    I          : Integer;
    Modified   : Boolean;
begin
   if not Owner.ProjectSettings.FMainparticularsHasBeenset then
   begin
      MessageDlg(Userstring(96),mtError,[mbOk],0);
      exit;
   end;
   Dialog:=TFreeLackenbyDialog.Create(Owner);
   ShowTranslatedValues(Dialog);
   Undo:=CreateUndoObject(Userstring(159),false);
   UndoIndex:=Owner.UndoCount;
   if Dialog.Execute(Owner,Modified) then
   begin
      for I:=Owner.UndoCount downto UndoIndex+1 do Owner.UndoObject[I-1].Delete;
      if not Modified then Undo.Delete
                      else Undo.Accept;
   end else
   begin
      for I:=Owner.UndoCount downto UndoIndex+1 do Owner.UndoObject[I-1].Delete;
      if Modified then Undo.Restore;
      Undo.Delete;
   end;
   Dialog.Destroy;
end;{TFreeEdit.Model_LackenbyTransformation}

// Scale the entire model and all equivalent data such as stations etc.
procedure TFreeEdit.Model_Scale(ScaleVector:T3DCoordinate;OverrideLock,AdjustMarkers:Boolean);
var I,J     : integer;
    Point   : TFreeSubdivisionControlPoint;
    P       : T3DCoordinate;
    Marker  : TFreeMarker;
begin
   for I:=1 to Owner.Surface.NumberOfControlPoints do
   begin
      Point:=Owner.Surface.ControlPoint[I-1];
      if (not Point.Locked) or (OverrideLock) then
      begin
         P:=Point.Coordinate;
         P.X:=P.X*ScaleVector.X;
         P.Y:=P.Y*ScaleVector.Y;
         P.Z:=P.Z*ScaleVector.Z;
         if Point.Locked then
         begin
            Point.Locked:=False;
            try
               Point.Coordinate:=P;
            finally
               Point.Locked:=True;
            end;
         end else Point.Coordinate:=P;
      end;
   end;
   // Update Mainparticulars
   Owner.ProjectSettings.ProjectLength:=abs(Owner.ProjectSettings.ProjectLength*Scalevector.X);
   Owner.ProjectSettings.ProjectBeam:=abs(Owner.ProjectSettings.ProjectBeam*Scalevector.Y);
   Owner.ProjectSettings.ProjectDraft:=abs(Owner.ProjectSettings.ProjectDraft*Scalevector.Z);
   if not Owner.ProjectSettings.FUseDefaultMainframeLocation then Owner.ProjectSettings.ProjectMainframeLocation:=abs(Owner.ProjectSettings.ProjectMainframeLocation*ScaleVector.X);
   // Update markers
   if AdjustMarkers then for I:=1 to Owner.NumberOfMarkers do
   begin
      Marker:=Owner.Marker[I-1];
      for j:=1 to Marker.NumberOfPoints do
      begin
         P:=Marker.Point[J-1];
         P.X:=P.X*Scalevector.X;
         P.Y:=P.Y*Scalevector.Y;
         P.Z:=P.Z*Scalevector.Z;
         Marker.Point[J-1]:=P;
      end;
   end;
   // Update stations, buttcks and waterlines
   for I:=1 to Owner.NumberofStations do Owner.Station[I-1].FPlane.d:=Owner.Station[I-1].FPlane.d*ScaleVector.X;
   for I:=1 to Owner.NumberofButtocks do Owner.Buttock[I-1].FPlane.d:=Owner.Buttock[I-1].FPlane.d*ScaleVector.Y;
   for I:=1 to Owner.NumberofWaterlines do Owner.Waterline[I-1].FPlane.d:=Owner.Waterline[I-1].FPlane.d*ScaleVector.Z;
   // Refresh controlpoint data
   Owner.ActiveControlPoint:=Owner.ActiveControlPoint;
   // Reset any present hydrostatic calculations
   for I:=1 to Owner.NumberOfHydrostaticCalculations do
   begin
      Owner.HydrostaticCalculation[I-1].Draft:=abs(Owner.HydrostaticCalculation[I-1].Draft*ScaleVector.Z);
      Owner.HydrostaticCalculation[I-1].Trim:=Owner.HydrostaticCalculation[I-1].Trim*ScaleVector.Z;
      Owner.HydrostaticCalculation[I-1].Calculated:=False;
   end;
   // scale data used for KAPER series resistance calculations
   with Owner.FResistanceKaperData do
   begin
      Draft:=Draft*ScaleVector.Z;
      Lwl:=Lwl*ScaleVector.X;
      Bwl:=Bwl*ScaleVector.Y;
      Displacement:=Displacement*ScaleVector.X*ScaleVector.Y*ScaleVector.Z;
      WettedSurface:=WettedSurface*ScaleVector.X*ScaleVector.Z;
   end;

   // scale data used for DELFT series resistance calculations
   with FOwner.FResistanceDelftData do
   begin
      Bwl:=Bwl*ScaleVector.Y;
      Displacement:=Displacement*ScaleVector.X*ScaleVector.Y*ScaleVector.Z;
      Draft:=Draft*ScaleVector.Z;
      DraftTotal:=DraftTotal*ScaleVector.Z;
      KeelChordLength:=KeelChordLength*ScaleVector.X;
      KeelArea:=KeelArea*ScaleVector.X*ScaleVector.Z;
      Lwl:=Lwl*ScaleVector.X;
      RudderChordLength:=RudderChordlength*ScaleVector.X;
      RudderArea:=RudderArea*ScaleVector.X*ScaleVector.Z;
      WettedSurface:=WettedSurface*ScaleVector.X*ScaleVector.Z;
      WlArea:=WlArea*ScaleVector.X*ScaleVector.Y;
   end;

   // Initialize all other data
   Owner.Build:=False;
   // Redraw
   Owner.FileChanged:=True;
   Owner.Draw;
end;{TFreeEdit.Model_Scale}

// Merge two selected edges by removing their common controlpoint.
procedure TFreeEdit.Point_Collapse;
var I,N   : integer;
    Point : TFreeSubdivisionControlPoint;
    Undo  : TFreeUndoObject;
begin
   N:=0;
   Undo:=CreateUndoObject(Userstring(160),false);
   For I:=Owner.NumberOfSelectedControlPoints downto 1 do
   begin
      Point:=Owner.SelectedControlPoint[I-1];
      if (not Point.Locked) and (Point.NumberOfEdges=2) then
      begin
         Point.Collapse;
         inc(N);
      end;
   end;
   if N>0 then
   begin
      Undo.Accept;
      Owner.Build:=false;
      Owner.Redraw;
      Owner.FileChanged:=True;
      if Assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(self);
   end else Undo.Delete;
end;{TFreeEdit.Point_Collapse}

// removes any unused points from the model
procedure TFreeEdit.Point_RemoveUnused;
var I,N   : integer;
    Point : TFreeSubdivisionControlPoint;
    Undo  : TFreeUndoObject;
begin
   N:=0;
   Undo:=CreateUndoObject(Userstring(161),false);
   For I:=Owner.Surface.NumberOfControlPoints downto 1 do
   begin
      Point:=Owner.Surface.ControlPoint[I-1];
      if Point.NumberOfFaces=0 then
      begin
         Point.Delete;
         inc(N);
      end;
   end;
   if N>0 then
   begin
      Undo.Accept;
      Owner.Build:=false;
      Owner.Redraw;
      Owner.FileChanged:=True;
      if Assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(self);
      MessageDlg(IntToStr(N)+#32+Userstring(162),mtInformation,[mbOk],0);
   end else Undo.Delete;
end;{TFreeEdit.Point_RemoveUnused}

// Finds all intersection of VISIBLE edges and a 3D plane, and inserts a point on each of these edges
procedure TFreeEdit.Point_InsertPlane;
var Dialog  : TFreeInsertPlaneDialog;
    Min,Max : T3DCoordinate;
    Undo    : TFreeUndoObject;
    N       : Integer;
begin
   Owner.Extents(Min,Max);
   Dialog:=TFreeInsertPlaneDialog.Create(Owner);
   ShowTranslatedValues(Dialog);
   Dialog.Max:=Max;
   Dialog.Min:=min;
   if Dialog.Execute then
   begin
      Undo:=CreateUndoObject(UserString(163),false);
      N:=Owner.Surface.NumberOfControlPoints;
      Owner.Surface.InsertPlane(Dialog.Plane,Dialog.CreateControlCurve);
      if N<Owner.Surface.NumberOfControlPoints then
      begin
         Undo.Accept;
         Owner.FileChanged:=True;
         Owner.Build:=false;
         Owner.Redraw;
         if Assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(self);
      end else Undo.Delete; // nothis has been changed
   end;
   Dialog.Destroy;
end;{TFreeEdit.Point_InsertPlane}

// Calculates the intersection points of two layers
procedure TFreeEdit.Point_IntersectLayer;
var I       : Integer;
    Layers  : TFasterList;
    Undo    : TFreeUndoObject;
    Dialog  : TFreeIntersectLayerDialog;
begin
   Layers:=TFasterList.Create;
   for I:=1 to Owner.NumberOfLayers do if Owner.Layer[I-1].Count>0 then Layers.Add(Owner.Layer[I-1]);
   if Layers.Count>1 then
   begin
      Dialog:=TFreeIntersectLayerDialog.Create(Owner);
      ShowTranslatedValues(Dialog);
      if Dialog.Execute(Layers) then
      begin
         if (Dialog.Layer1<>nil) and (Dialog.Layer2<>nil) then
         begin
            Undo:=CreateUndoObject(Userstring(164),false);
            if Dialog.Layer1.CalculateIntersectionPoints(Dialog.Layer2) then
            begin
               Undo.Accept;
               Owner.FileChanged:=True;
               Owner.Build:=False;
               Owner.Redraw;
               if Assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(self);
            end else
            begin
               Undo.Delete;
               MessageDlg(Userstring(165),mtInformation,[mbOk],0);
            end;
         end;
      end;
      Dialog.Destroy;
   end else MessageDlg(Userstring(166),mtError,[mbOk],0);
   Layers.Destroy;
end;{TFreeEdit.Point_IntersectLayer}

// Locks all selected points
procedure TFreeEdit.Point_Lock;
var I:Integer;
begin
   if Owner.NumberOfSelectedLockedPoints<Owner.NumberOfSelectedControlPoints then
   begin
      self.CreateUndoObject(UserString(167),True);
      for I:=1 to Owner.NumberOfSelectedControlPoints do Owner.SelectedControlPoint[I-1].Locked:=True;
      Owner.ActiveControlPoint:=Owner.ActiveControlPoint;
      Owner.Redraw;
      Owner.FileChanged:=True;
   end;
end;{TFreeEdit.Point_Lock}

// Unlocks all selected locked points
procedure TFreeEdit.Point_Unlock;
var I:Integer;
begin
   if Owner.NumberOfSelectedLockedPoints>0 then
   begin
      self.CreateUndoObject(Userstring(168),True);
      for I:=1 to Owner.NumberOfSelectedControlPoints do Owner.SelectedControlPoint[I-1].Locked:=False;
      Owner.ActiveControlPoint:=Owner.ActiveControlPoint;
      Owner.Redraw;
      Owner.FileChanged:=True;
   end;
end;{TFreeEdit.Point_Unlock}

// Unlocks all locked points
procedure TFreeEdit.Point_UnlockAll;
var I,N:Integer;
begin
   if Owner.NumberOfLockedPoints>0 then
   begin
      CreateUndoObject(Userstring(169),True);
      N:=Owner.NumberOfLockedPoints;
      for I:=1 to Owner.Surface.NumberOfControlPoints do Owner.Surface.ControlPoint[I-1].Locked:=False;
      Owner.ActiveControlPoint:=Owner.ActiveControlPoint;
      Owner.Redraw;
      MessageDlg(IntToStr(N)+#32+Userstring(170)+'.',mtInformation,[mbOK],0);
      Owner.FileChanged:=True;
   end;
end;{TFreeEdit.Point_UnlockAll}

// Function that shows a warning when certain edit commands are invoked and the model contains locked points
function TFreeEdit.ProceedWhenLockedPoints:Boolean;
begin
   if Owner.NumberOfLockedPoints>0 then
   begin
      Result:=MessageDlg(Userstring(86)+EOL+
                         Userstring(87),mtWarning,[mbYes,mbNo],0)=mrYes;
   end else Result:=True;
end;{TFreeEdit.ProceedWhenLockedPoints}

// Calculate resistance of yachts according to Delft systematic yacht series
procedure TFreeEdit.Resistance_Delft;
var Dialog:TFreeResistance_Delft;
begin
   Dialog:=TFreeResistance_Delft.create(Owner);
   ShowTranslatedValues(Dialog);
   Dialog.Bwl:=Owner.FResistanceDelftData.Bwl;
   Dialog.Cp:=Owner.FResistanceDelftData.Cp;
   Dialog.Density:=Owner.ProjectSettings.ProjectWaterDensity;
   Dialog.Displacement:=Owner.FResistanceDelftData.Displacement;
   Dialog.Draft:=Owner.FResistanceDelftData.Draft;
   Dialog.DraftTotal:=Owner.FResistanceDelftData.DraftTotal;
   Dialog.EndSpeed:=Owner.FResistanceDelftData.EndSpeed;
   Dialog.ExtractFromHull:=Owner.FResistanceDelftData.Extract;
   Dialog.KeelChordLength:=Owner.FResistanceDelftData.KeelChordLength;
   Dialog.KeelArea:=Owner.FResistanceDelftData.KeelArea;
   Dialog.LCB:=Owner.FResistanceDelftData.LCB;
   Dialog.Lwl:=Owner.FResistanceDelftData.Lwl;
   Dialog.RudderChordLength:=Owner.FResistanceDelftData.RudderChordLength;
   Dialog.RudderArea:=Owner.FResistanceDelftData.RudderArea;
   Dialog.StartSpeed:=Owner.FResistanceDelftData.StartSpeed;
   Dialog.StepSpeed:=Owner.FResistanceDelftData.StepSpeed;
   Dialog.Viscosity:=Owner.FResistanceDelftData.Viscosity;
   Dialog.WettedSurface:=Owner.FResistanceDelftData.WettedSurface;
   Dialog.WlArea:=Owner.FResistanceDelftData.WlArea;
   if Dialog.Execute(Owner,Owner.FResistanceDelftData.Extract) then
   begin
      Owner.FResistanceDelftData.Bwl:=Dialog.Bwl;
      Owner.FResistanceDelftData.Cp:=Dialog.Cp;
      Owner.ProjectSettings.ProjectWaterDensity:=Dialog.Density;
      Owner.FResistanceDelftData.Displacement:=Dialog.Displacement;
      Owner.FResistanceDelftData.Draft:=Dialog.Draft;
      Owner.FResistanceDelftData.DraftTotal:=Dialog.DraftTotal;
      Owner.FResistanceDelftData.EndSpeed:=Dialog.EndSpeed;
      Owner.FResistanceDelftData.Extract:=Dialog.ExtractFromHull;
      Owner.FResistanceDelftData.KeelChordLength:=Dialog.KeelChordLength;
      Owner.FResistanceDelftData.KeelArea:=Dialog.KeelArea;
      Owner.FResistanceDelftData.LCB:=Dialog.LCB;
      Owner.FResistanceDelftData.Lwl:=Dialog.Lwl;
      Owner.FResistanceDelftData.RudderChordLength:=Dialog.RudderChordLength;
      Owner.FResistanceDelftData.RudderArea:=Dialog.RudderArea;
      Owner.FResistanceDelftData.StartSpeed:=Dialog.StartSpeed;
      Owner.FResistanceDelftData.StepSpeed:=Dialog.StepSpeed;
      Owner.FResistanceDelftData.Viscosity:=Dialog.Viscosity;
      Owner.FResistanceDelftData.WettedSurface:=Dialog.WettedSurface;
      Owner.FResistanceDelftData.WlArea:=Dialog.WlArea;
      Owner.FileChanged:=True;
   end;
   Dialog.Destroy;
end;{TFreeEdit.Resistance_Delft}
      
// Calculate resistance of slender hulls (canoes) according to John Winters
procedure TFreeEdit.Resistance_Kaper;
var Dialog : TFreeResistance_Kaper;
begin
   Dialog:=TFreeResistance_Kaper.Create(Owner);
   ShowTranslatedValues(Dialog);
   Dialog.Ewl:=Owner.FResistanceKaperData.Lwl;
   Dialog.Bwl:=Owner.FResistanceKaperData.Bwl;
   Dialog.Cp:=Owner.FResistanceKaperData.Cp;
   Dialog.Displ:=Owner.FResistanceKaperData.Displacement;
   Dialog.H:=Owner.FResistanceKaperData.Draft;
   Dialog.LCB:=Owner.FResistanceKaperData.LCB;
   Dialog.Ws:=Owner.FResistanceKaperData.WettedSurface;
   Dialog.At_Ax:=Owner.FResistanceKaperData.At_Ax;
   Dialog.Ie:=Owner.FResistanceKaperData.EntranceAngle;
   if Dialog.Execute(Owner,Owner.FResistanceKaperData.Extract) then
   begin
      Owner.FResistanceKaperData.Lwl:=Dialog.Ewl;
      Owner.FResistanceKaperData.Bwl:=Dialog.Bwl;
      Owner.FResistanceKaperData.Cp:=Dialog.Cp;
      Owner.FResistanceKaperData.Displacement:=Dialog.Displ;
      Owner.FResistanceKaperData.Draft:=Dialog.H;
      Owner.FResistanceKaperData.LCB:=Dialog.LCB;
      Owner.FResistanceKaperData.WettedSurface:=Dialog.Ws;
      Owner.FResistanceKaperData.At_Ax:=Dialog.At_Ax;
      Owner.FResistanceKaperData.EntranceAngle:=Dialog.Ie;
      Owner.FResistanceKaperData.Extract:=Dialog.CheckBox2.Checked;
      Owner.FileChanged:=True;
   end;
   Dialog.Destroy;
end;{TFreeEdit.Resistance_Kaper}

// Add a new point to the model with no edges/faces attached
function TFreeEdit.Point_New:TFreeSubdivisionControlPoint;
begin
   Result:=TFreeSubdivisionControlPoint.Create(Owner.Surface);
   Owner.Surface.AddControlPoint(Result);
   Result.Coordinate:=ZERO;
   Owner.ActiveControlPoint:=Result;
   Owner.FileChanged:=true;
   Owner.Redraw;
   if Assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(self);
end;{TFreeEdit.Point_New}

// Project all selected points onto a straight line through the first and last selected points
procedure TFreeEdit.Point_ProjectStraightLine;
var I       : Integer;
    NLocked : Integer;
    NChanged: Integer;
    Point   : TFreeSubdivisionControlPoint;
    P1,P2   : TFreeSubdivisionControlPoint;
    P       : T3DCoordinate;
    Undo    : TFreeUndoObject;
begin
   if Owner.NumberOfSelectedControlPoints>2 then
   begin
      // Determine if the number of points to be moved does not conatin locked controlpoints only
      // however the first and last points (determining the linesegment) are allowed to be locked
      NLocked:=0;
      for I:=2 to Owner.NumberOfSelectedControlPoints-1 do if Owner.SelectedControlPoint[I-1].Locked then inc(NLocked);
      // Number of lovked points must be smaller then NumberOfSelectedControlPoints-2
      if NLocked<Owner.NumberOfSelectedControlPoints-2 then
      begin
         P1:=Owner.SelectedControlPoint[0];
         P2:=Owner.SelectedControlPoint[Owner.NumberOfSelectedControlPoints-1];
         Undo:=CreateUndoObject(userstring(171),False);
         NChanged:=0;
         for I:=2 to Owner.NumberOfSelectedControlPoints-1 do
         begin
            Point:=Owner.SelectedControlPoint[I-1];
            if not Point.Locked then
            begin
               P:=ProjectPointOnline(Point.Coordinate,P1.Coordinate,P2.Coordinate);
               if DistPP3D(P,Point.Coordinate)>1e-5 then
               begin
                  Point.Coordinate:=P;
                  Inc(NChanged);
               end;
            end;
         end;
         if NChanged>0 then
         begin
            Undo.Accept;
            Owner.FileChanged:=True;
            Owner.Redraw;
         end else Undo.Delete;
      end else MessageDlg(Userstring(172)+'.',mtError,[mbOk],0);
   end;
end;{TFreeEdit.Point_ProjectStraightLine}

// Deselect all selected items at once
procedure TFreeEdit.Selection_Clear;
begin
   Owner.Surface.Clearselection;
   Owner.ActiveControlPoint:=nil;
   Owner.FSelectedFlowlines.Clear;
   Owner.FSelectedMarkers.Clear;
   Owner.Redraw;
end;{TFreeEdit.Selection_Clear}

procedure TFreeEdit.Selection_Delete;
var I,N  : integer;
begin
   N:=Owner.NumberOfSelectedControlPoints+
      Owner.NumberOfSelectedControlEdges+
      Owner.NumberOfSelectedControlFaces+
      Owner.NumberOfSelectedControlCurves+
      Owner.NumberOfselectedMarkers+
      Owner.NumberOfselectedFlowlines;
   if N>0 then
   begin
      if MessageDlg(Userstring(173)+#32+IntToStr(N)+#32+Userstring(174)+'?',mtWarning,[mbYes,mbNo],0)=mrYes then
      begin
         CreateUndoObject(Userstring(175),True);
         for I:=Owner.NumberOfselectedFlowlines downto 1 do Owner.SelectedFlowline[I-1].Delete;
         for I:=Owner.NumberOfselectedMarkers downto 1 do Owner.SelectedMarker[I-1].Delete;
         Owner.Surface.Selection_Delete;
         Owner.ActiveControlPoint:=nil;
         Owner.Build:=False;
         Owner.FileChanged:=True;
         Owner.Redraw;
         if Assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(self);
      end;
   end;
end;{TFreeEdit.Selection_Delete}

// Select all visible items
procedure TFreeEdit.Selection_SelectAll;
var I,J:Integer;
begin
   for I:=1 to Owner.NumberOfLayers do if Owner.Layer[I-1].Visible then
   begin
      for J:=1 to Owner.Layer[I-1].Count do Owner.Layer[I-1].Items[J-1].Selected:=True;
   end;
   for I:=1 to Owner.Surface.NumberOfControlEdges do if Owner.Surface.ControlEdge[I-1].Visible then Owner.Surface.ControlEdge[I-1].Selected:=True;
   for I:=1 to Owner.Surface.NumberOfControlPoints do if Owner.Surface.ControlPoint[I-1].Visible then Owner.Surface.ControlPoint[I-1].Selected:=True;
   for I:=1 to Owner.Surface.NumberOfControlCurves do if Owner.Surface.ControlCurve[I-1].Visible then Owner.Surface.ControlCurve[I-1].Selected:=True;
   for I:=1 to Owner.NumberofMarkers do if Owner.Marker[I-1].Visible then Owner.Marker[I-1].Selected:=True;
   for I:=1 to Owner.NumberofFlowlines do if Owner.Flowline[I-1].Visible then Owner.Flowline[I-1].Selected:=True;
   Owner.Redraw;
end;{TFreeEdit.Selection_SelectAll}

procedure TFreeEdit.Undo;
var UndoObject : TFreeUndoObject;
    Preview    : boolean;
begin
   if Owner.FUndoObjects.Count>0 then
   begin
      Preview:=Owner.ProjectSettings.SavePreview;
      try
         if Owner.FUndoPosition=owner.UndoCount then
         begin
            if Owner.UndoObject[Owner.UndoCount-1].FIsTempRedoObject then
            begin
            end else CreateRedoObject;
         end;
         if Owner.FPreviousUndoPosition<Owner.FUndoPosition then dec(Owner.FUndoPosition);
         Owner.FPreviousUndoPosition:=Owner.FUndoPosition;
         dec(Owner.FUndoPosition);
         UndoObject:=Owner.FUndoObjects[Owner.FUndoPosition];
         UndoObject.Restore;
      finally
         Owner.ProjectSettings.SavePreview:=Preview;
      end;
   end;
end;{TFreeEdit.Undo}

// Clear the undo history
procedure TFreeEdit.Undo_Clear;
begin
   Owner.ClearUndo;
end;{TFreeEdit.Undo_Clear}

// Show the undo history
procedure TFreeEdit.Undo_ShowHistory;
var Dialog     : TFreeUndoHistoryDialog;
    Undo       : TFreeUndoObject;
    Index      : Integer;
    Redo       : TFreeUndoObject;
begin
   Dialog:=TFreeUndoHistoryDialog.Create(Owner);
   ShowTranslatedValues(Dialog);
   Redo:=nil;
   if (Owner.FUndoPosition=owner.UndoCount) and (Owner.UndoCount>0) then
   begin
      if not Owner.UndoObject[Owner.UndoCount-1].FIsTempRedoObject then
      begin
         Redo:=CreateRedoObject;
         dec(Owner.FUndoPosition);
      end;
   end;

   if Dialog.Execute(Owner) then
   begin
      if Dialog.UndoBox.ItemIndex<>-1 then
      begin
         Undo:=Dialog.UndoBox.Items.Objects[Dialog.UndoBox.ItemIndex] as TFreeUndoObject;;
         Index:=Owner.FUndoObjects.IndexOf(Undo);
         if Index<>-1 then
         begin
            //Owner.FPreviousUndoPosition:=Index+1;
            Owner.FUndoPosition:=Index;
            Undo.Restore;
         end;
      end;
   end else if Redo<>nil then Redo.Delete;
   Dialog.Destroy;
end;{TFreeEdit.Undo_ShowHistory}

procedure TFreeEdit.Redo;
var UndoObject : TFreeUndoObject;
    Preview    : boolean;
begin
   if Owner.FUndoObjects.Count>0 then
   begin
      Preview:=Owner.ProjectSettings.SavePreview;
      try
         if Owner.FPreviousUndoPosition>Owner.FUndoPosition then inc(Owner.FUndoPosition);
         Owner.FPreviousUndoPosition:=Owner.FUndoPosition;
         inc(Owner.FUndoPosition);
         UndoObject:=Owner.FUndoObjects[Owner.FUndoPosition-1];
         UndoObject.Restore;
      finally
         Owner.ProjectSettings.SavePreview:=Preview;
      end;
   end;
end;{TFreeEdit.Redo}

// Add a new intersection of the specified type at the specified location
function  TFreeEdit.Intersection_Add(IntType:TFreeIntersectionType;Distance:TFloatType):TFreeIntersection;
var Intersection  : TFreeIntersection;
    TargetList    : TFasterList;
    I             : integer;
begin
   TargetList:=nil;
   Case IntType of
      fiStation    : TargetList:=Owner.FStations;
      fiButtock    : TargetList:=Owner.FButtocks;
      fiWaterline  : TargetList:=Owner.FWaterlines;
      fiDiagonal   : TargetList:=Owner.FDiagonals;
   end;
   // First check if an intersection already exists at this location;
   for I:=1 to TargetList.Count do
   begin
      Intersection:=TargetList[I-1];
      if Abs(-InterSection.FPlane.d-Distance)<1e-5 then
      begin
         // Yes, it exists, so do not add a new one
         Result:=nil;
         exit;
      end;
   end;
   // Once here, a new intersection can be added
   Intersection:=TFreeIntersection.Create(Owner);
   Intersection.FIntersectionType:=IntType;
   Intersection.FPlane.a:=0.0;
   Intersection.FPlane.b:=0.0;
   Intersection.FPlane.c:=0.0;
   Intersection.FPlane.d:=0.0;
   Case Intersection.IntersectionType of
      fiStation    : begin
                        Intersection.FPlane.a:=1.0;
                        Intersection.FPlane.d:=-Distance;
                     end;
      fiButtock    : begin
                        Intersection.FPlane.b:=1.0;
                        Intersection.FPlane.d:=-Distance;
                     end;
      fiWaterline  : begin
                        Intersection.FPlane.c:=1.0;
                        Intersection.FPlane.d:=-Distance;
                     end;
      fiDiagonal   : begin
                        Intersection.FPlane.b:=1/Sqrt(2);
                        Intersection.FPlane.c:=1/Sqrt(2);
                        Intersection.FPlane.d:=-Intersection.FPlane.c*Distance;
                     end;
   end;
   Intersection.Rebuild;
   // Only add if an intersection has been found
   if Intersection.Count>0 then
   begin
      Intersection_AddToList(Intersection);
      Intersection.DrawAll;
      Result:=Intersection;
   end else
   begin
      Intersection.Destroy;
      Result:=nil;
   end;
end;{TFreeEdit.Intersection_Add}

{---------------------------------------------------------------------------------------------------}
{                                       TFreePreferences                                            }
{                                                                                                   }
{   Container class for all program settings                                                        }
{---------------------------------------------------------------------------------------------------}
function TFreePreferences.FGetExportDirectory:string;
begin
   if DirectoryExists(FExportDirectory) then result:=FExportDirectory
                                        else Result:=ExtractFilePath(Application.ExeName);
end;{TFreePreferences.FGetExportDirectory}

function TFreePreferences.FGetImportDirectory:string;
begin
   if DirectoryExists(FImportDirectory) then result:=FImportDirectory
                                        else Result:=ExtractFilePath(Application.ExeName);
end;{TFreePreferences.FGetImportDirectory}

function TFreePreferences.FGetOpenDirectory:string;
begin
   if DirectoryExists(FOpenDirectory) then result:=FOpenDirectory
                                      else Result:=ExtractFilePath(Application.ExeName);
end;{TFreePreferences.FGetOpenDirectory}

function TFreePreferences.FGetSaveDirectory:string;
begin
   if DirectoryExists(FSaveDirectory) then result:=FSaveDirectory
                                      else Result:=ExtractFilePath(Application.ExeName);
end;{TFreePreferences.FGetSaveDirectory}

procedure TFreePreferences.FSetViewportColor(Val:TColor);
var I : integer;
begin
   FViewportColor:=Val;
   for I:=1 to Owner.NumberOfViewports do Owner.Viewport[I-1].Color:=FViewportColor;
end;{TFreePreferences.FSetViewportColor}

procedure TFreePreferences.Clear;
begin
   ResetColors;
   FPointSize:=2;
   FOpenDirectory:=ExtractFilePath(Application.ExeName);
   FSaveDirectory:=ExtractFilePath(Application.ExeName);
   FImportDirectory:=ExtractFilePath(Application.ExeName);
   FExportDirectory:=ExtractFilePath(Application.ExeName);
   FLanguageFile:='English';
   FMaxUndoMemory:=20;// Max 20Mb undomemory
end;{TFreePreferences.Clear}

constructor TFreePreferences.Create(Owner:TFreeShip);
begin
   inherited Create;
   FOwner:=Owner;
   Clear;
end;{TFreePreferences.Create}

procedure TFreePreferences.Edit;
var Dialog  : TFreePreferencesDialog;
    Filename: string;
    I       : Integer;
    Dir     : string;

   procedure Browse(Dir:string);
   var SearchRec  : TSearchRec;

      procedure Add(FileName:string);
      var Tmp:String;
          I:Integer;
          Found:Boolean;
      begin
         Tmp:=ChangeFileExt(ExtractFilename(Filename),'');
         found:=False;
         for I:=1 to Dialog.ComboBox1.Items.Count do if Uppercase(Tmp)=Uppercase(Dialog.Combobox1.Items[I-1]) then
         begin
            Found:=True;
            break;
         end;
         if not found then Dialog.Combobox1.Items.Add(Tmp);
      end;{Add}

   begin
      if Dir[Length(Dir)]<>'\' then Dir:=Dir+'\';
      if FindFirst(Dir+'*.ini',faAnyfile,SearchRec)=0 then
      begin
         if Uppercase(ExtractFileExt(SearchRec.Name))='.INI' then Add(Searchrec.Name);
         while FindNext(SearchRec)=0 do
         begin
            if (SearchRec.Name<>'.') and (SearchRec.Name<>'..') then
               if Uppercase(ExtractFileExt(SearchRec.Name))='.INI' then Add(Searchrec.Name);
         end;
         SysUtils.FindClose(SearchRec);
      end;
   end;{Browse}

begin
   Dialog:=TFreePreferencesDialog.Create(Owner);
   ShowTranslatedValues(Dialog);
   Dir:=ExtractFileDir(Application.ExeName)+'\Languages\';
   Dialog.ComboBox1.Items.Clear;
   Dialog.ComboBox1.Items.Add('English');
   Browse(Dir);
   Dialog.ComboBox1.ItemIndex:=0;
   for I:=1 to Dialog.ComboBox1.Items.Count do
   begin
      if Uppercase(Dialog.ComboBox1.Items[I-1])=Uppercase(LanguageFile) then
      begin
         Dialog.ComboBox1.ItemIndex:=I-1;
         break;
      end;
   end;

   if Dialog.Execute(Owner) then
   begin
      PointSize:=Dialog.TrackBar1.Position;
      LayerColor:=Dialog.Panel2.Color;
      UnderWaterColor:=Dialog.Panel5.Color;
      EdgeColor:=Dialog.Panel6.Color;
      CreaseEdgeColor:=Dialog.Panel7.Color;
      CreaseColor:=Dialog.Panel8.Color;
      RegularPointColor:=Dialog.Panel9.Color;
      CreasePointColor:=Dialog.Panel10.Color;
      CornerPointColor:=Dialog.Panel11.Color;
      DartPointColor:=Dialog.Panel12.Color;
      SelectColor:=Dialog.Panel13.Color;
      GridColor:=Dialog.Panel14.Color;
      GridFontColor:=Dialog.Panel15.Color;
      StationColor:=Dialog.Panel16.Color;
      ButtockColor:=Dialog.Panel17.Color;
      WaterlineColor:=Dialog.Panel18.Color;
      NormalColor:=Dialog.Panel19.Color;
      DiagonalColor:=Dialog.Panel20.Color;
      LeakPointColor:=Dialog.Panel21.Color;
      MarkerColor:=Dialog.Panel22.Color;
      CurvaturePlotColor:=Dialog.Panel23.Color;
      ControlCurveColor:=Dialog.Panel24.Color;
      HydrostaticsFontColor:=Dialog.Panel25.Color;
      ZebraStripeColor:=Dialog.Panel26.Color;
      ViewportColor:=Dialog.Panel4.Color; // Set viewportcolor last, because it forces a repaint
      Filename:=Dialog.Combobox1.Text;
      if Uppercase(Filename)<>Uppercase(LanguageFile) then
      begin
         if FileExists(ExtractFilePath(Application.ExeName)+'\Languages\'+Filename+'.ini') then
         begin
            LoadLanguage(Filename);
            LanguageFile:=Filename;
            for I:=1 to Application.ComponentCount do
            begin
               if Application.Components[I-1] is TCustomForm then
                  ShowTranslatedValues(Application.Components[I-1]);
            end;
            for I:=1 to Application.MainForm.MDIChildCount do
            begin
               if Application.Mainform.MDIChildren[I-1] is TFreeLinesplanForm then
               begin
                  ShowTranslatedValues(TFreeLinesplanForm(Application.Mainform.MDIChildren[I-1]).LinesplanFrame);
               end else ShowTranslatedValues(Application.Mainform.MDIChildren[I-1]);
            end;
         end else LanguageFile:=Filename;
      end;
      FMaxUndoMemory:=Dialog.FreeNumInput1.AsInteger;
      if assigned(Owner.FOnFileChanged) then Owner.FOnFileChanged(Owner);
      if assigned(Owner.FOnUpdateUndoData) then Owner.FOnUpdateUndoData(Owner);
      if assigned(Owner.FOnUpdateRecentFileList) then Owner.FOnUpdateRecentFileList(Owner);
      if assigned(Owner.FOnChangeCursorIncrement) then Owner.FOnChangeCursorIncrement(Owner);
      if assigned(Owner.FOnUpdateGeometryInfo) then Owner.FOnUpdateGeometryInfo(owner);
      Owner.Redraw;
      Save;
   end;
   Dialog.Destroy;
end;{TFreePreferences.Edit}

procedure TFreePreferences.Load;
var FileName: string;
    FFile   : TextFile;
    I,N     : Integer;
    T,L,W,H,S:Integer;
begin
   Filename:=ChangeFileExt(Application.ExeName,'.dta');
   if FileExists(Filename) then
   begin
      AssignFile(FFile,Filename);
      Try
         clear;
         Reset(FFile);
         Readln(FFile,FPointSize);
         Readln(FFile,FButtockColor);
         Readln(FFile,FWaterlineColor);
         Readln(FFile,FStationColor);
         Readln(FFile,FCreaseColor);
         Readln(FFile,FCreaseEdgeColor);
         Readln(FFile,FGridColor);
         Readln(FFile,FGridFontColor);
         Readln(FFile,FEdgeColor);
         Readln(FFile,FCreasePointColor);
         Readln(FFile,FRegularPointColor);
         Readln(FFile,FCornerPointColor);
         Readln(FFile,FDartPointColor);
         Readln(FFile,FSelectColor);
         Readln(FFile,FLayerColor);
         Readln(FFile,FUnderWaterColor);
         Readln(FFile,FNormalColor);
         Readln(FFile,FViewportColor);
         if not EOF(FFile) then readln(FFile,FOpenDirectory);
         if not EOF(FFile) then readln(FFile,FSaveDirectory);
         if not EOF(FFile) then readln(FFile,FImportDirectory);
         if not EOF(FFile) then readln(FFile,FExportDirectory);
         if not EOF(FFile) then readln(FFile,FDiagonalColor);
         if not EOF(FFile) then
         begin
            // load recent files
            Readln(FFile,N);
            Owner.Edit.FRecentFiles.Clear;
            Owner.Edit.FRecentFiles.Capacity:=N;
            for I:=1 to N do
            begin
               Readln(FFile,Filename);
               // only add the file to the list if it is a valid filename
               if FileExists(Filename+'.fbm') then Owner.Edit.FRecentFiles.Add(Filename);
            end;
            if assigned(Owner.FOnUpdateRecentFileList) then Owner.FOnUpdateRecentFileList(self);
         end;
         if not EOF(FFile) then Readln(FFile,FLeakPointColor);
         if not EOF(FFile) then readln(FFile,FMarkerColor);
         if not EOF(FFile) then Readln(FFile,FCurvaturePlotColor);
         if not EOF(FFile) then Readln(FFile,FControlCurveColor);
         if not EOF(FFile) then readln(FFile,FHydrostaticsFontColor);
         if not EOF(FFile) then readln(FFile,FZebraStripeColor);
         if not EOF(FFile) then
         begin
            Readln(FFile,T,L,H,W,S);
            if Application.Mainform<>nil then
            begin
               if L>Screen.Width then L:=0;
               if T>Screen.Height then T:=0;
               case TWindowState(S) of
                  wsNormal	      : Application.MainForm.SetBounds(L,T,W,H);
                  wsMinimized	   : begin
                                      Application.MainForm.WindowState:=wsNormal;
                                      Application.MainForm.SetBounds(L,T,W,H);
                                   end;
                  wsMaximized	   : Application.MainForm.WindowState:=wsMaximized;
               end;
            end;
         end;
         if not EOF(FFile) then Readln(FFile,FLanguageFile)
                           else FLanguageFile:='English';
         Filename:=ExtractFilePath(Application.Exename)+'Languages\'+FlanguageFile+'.ini';
         if not FileExists(Filename) then FLanguageFile:='English';
         if not EOF(FFile) then Readln(FFile,FMaxUndoMemory);
         CloseFile(FFile);
      except
         MessageDlg(Userstring(176)+':'+EOL+Filename,mtError,[mbOk],0);
      end;
   end;
end;{TFreePreferences.Load}

procedure TFreePreferences.ResetColors;
begin
   FButtockColor:=$00808040;     // Kind of teal-blue
   FWaterlineColor:=$00808040;   // Kind of teal-blue
   FStationColor:=$00808040;     // Kind of teal-blue
   FDiagonalColor:=$00808040;     // Kind of teal-blue
   FCreaseColor:=clBlack;        // color of descendants from crease controledges
   FCreaseEdgeColor:=clRed;      // Color of crease control edges
   FGridColor:=clSilver;
   FGridFontColor:=clWhite;
   FEdgeColor:=$006F6F6F;
   FCreasePointColor:=$00004080;
   FRegularPointColor:=$00E1E1E1;
   FCornerPointColor:=$00B95C00;
   FDartPointColor:=clFuchsia;
   FSelectColor:=clYellow;
   FLayerColor:=RGB(0,128,0);       // Default color of each layer (green-ish)
   FViewportColor:=$009F9F9F;
   FUnderwaterColor:=RGB(240,240,240);
   FLeakPointColor:=$0099FF00;
   FNormalColor:=clWhite;
   FMarkerColor:=$008000FF;
   FCurvaturePlotColor:=clFuchsia;
   FControlCurveColor:=16711808;
   FHydrostaticsFontColor:=clMaroon;
   FZebraStripeColor:=RGB(230,230,230);
end;{TFreePreferences.ResetColors}

procedure TFreePreferences.Save;
var FileName: string;
    FFile   : TextFile;
    I       : Integer;
begin
   Filename:=ChangeFileExt(Application.ExeName,'.dta');
   AssignFile(FFile,Filename);
   Try
      Rewrite(FFile);
      Writeln(FFile,FPointSize);
      Writeln(FFile,FButtockColor);
      Writeln(FFile,FWaterlineColor);
      Writeln(FFile,FStationColor);
      Writeln(FFile,FCreaseColor);
      Writeln(FFile,FCreaseEdgeColor);
      Writeln(FFile,FGridColor);
      Writeln(FFile,FGridFontColor);
      Writeln(FFile,FEdgeColor);
      Writeln(FFile,FCreasePointColor);
      Writeln(FFile,FRegularPointColor);
      Writeln(FFile,FCornerPointColor);
      Writeln(FFile,FDartPointColor);
      Writeln(FFile,FSelectColor);
      Writeln(FFile,FLayerColor);
      Writeln(FFile,FUnderWaterColor);
      Writeln(FFile,FNormalColor);
      Writeln(FFile,FViewportColor);
      Writeln(FFile,FOpenDirectory);
      Writeln(FFile,FSaveDirectory);
      Writeln(FFile,FImportDirectory);
      Writeln(FFile,FExportDirectory);
      Writeln(FFile,FDiagonalColor);
      // save list with recently used files
      writeln(FFile,Owner.Edit.RecentFileCount);
      for I:=1 to Owner.Edit.RecentFileCount do Writeln(FFile,Owner.Edit.RecentFile[I-1]);
      Writeln(FFile,FLeakPointColor);
      Writeln(FFile,FMarkerColor);
      Writeln(FFile,FCurvaturePlotColor);
      Writeln(FFile,FControlCurveColor);
      Writeln(FFile,FHydrostaticsFontColor);
      Writeln(FFile,FZebraStripeColor);
      Writeln(FFile,Application.Mainform.Top,#32,Application.Mainform.Left,#32,Application.Mainform.Height,#32,Application.Mainform.Width,#32,Ord(Application.MainForm.WindowState));
      Writeln(FFile,FLanguageFile);
      Writeln(FFile,FMaxUndoMemory);
      CloseFile(FFile);
   except
      MessageDlg(Userstring(177)+':'+EOL+Filename,mtError,[mbOk],0);
   end;
end;{TFreePreferences.Save}

{---------------------------------------------------------------------------------------------------}
{                                       TFreeProjectSettings                                        }
{                                                                                                   }
{   Container class for project settings for each project such as mainparticulars,                  }
{   waterdensity etc.                                                                               }
{---------------------------------------------------------------------------------------------------}
procedure TFreeProjectSettings.FSetFreeHydrostaticCoefficients(val:TFreeHydrostaticCoeff);
var I : Integer;
begin
   if val<>FFreeHydrostaticCoefficients then
   begin
      FFreeHydrostaticCoefficients:=val;
      Owner.FileChanged:=True;
      for I:=1 to Owner.NumberOfHydrostaticCalculations do Owner.HydrostaticCalculation[I-1].Calculated:=False;
   end;
end;{TFreeProjectSettings.FSetFreeHydrostaticCoefficients}

procedure TFreeProjectSettings.FSetDisableModelCheck(Val:Boolean);
begin
   if val<>FDisableModelCheck then
   begin
      FDisableModelCheck:=Val;
      Owner.FileChanged:=True;
   end;
end;{TFreeProjectSettings.FSetDisableModelCheck}

function TFreeProjectSettings.FGetProjectMainframeLocation:TFloatType;
begin
   if UseDefaultMainframeLocation then Result:=FProjectLength/2
                                  else Result:=FProjectMainframeLocation;
end;{TFreeProjectSettings.FGetProjectMainframeLocation}

procedure TFreeProjectSettings.FSetProjectAppendageCoefficient(Val:TFloatType);
begin
   if abs(Val-FProjectAppendageCoefficient)>1e-5 then
   begin
      FProjectAppendageCoefficient:=Val;
      Owner.FileChanged:=True;
   end;
end;{TFreeProjectSettings.FSetProjectAppendageCoefficient}

procedure TFreeProjectSettings.FSetProjectBeam(Val:TFloatType);
begin
   if abs(Val-FProjectBeam)>1e-5 then
   begin
      FProjectBeam:=Val;
      FMainparticularsHasBeenset:=True;
      Owner.FileChanged:=True;
   end;
end;{TFreeProjectSettings.FSetProjectBeam}

procedure TFreeProjectSettings.FSetProjectDraft(Val:TFloatType);
var I : Integer;
begin
   if abs(Val-FProjectDraft)>1e-5 then
   begin
      FProjectDraft:=Val;
      FMainparticularsHasBeenset:=True;
      Owner.FileChanged:=True;
      for I:=1 to Owner.NumberOfFlowLines do Owner.Flowline[I-1].Build:=False;
   end;
end;{TFreeProjectSettings.FSetProjectDraft}

procedure TFreeProjectSettings.FSetProjectLength(Val:TFloatType);
begin
   if abs(Val-FProjectLength)>1e-5 then
   begin
      FProjectLength:=Val;
      FMainparticularsHasBeenset:=True;
      Owner.FileChanged:=True;
   end;
end;{TFreeProjectSettings.FSetProjectLength}

procedure TFreeProjectSettings.FSetProjectMainframeLocation(val:TFloatType);
begin
   if Val<>FProjectMainframeLocation then
   begin
      FProjectMainframeLocation:=val;
      Owner.FileChanged:=True;
   end;
end;{TFreeProjectSettings.FSetProjectMainframeLocation}

procedure TFreeProjectSettings.FSetProjectWaterDensity(Val:TFloatType);
begin
   if abs(Val-FProjectWaterDensity)>1e-6 then
   begin
      FProjectWaterDensity:=Val;
      Owner.FileChanged:=True;
   end;
end;{TFreeProjectSettings.FSetProjectWaterDensity}

procedure TFreeProjectSettings.FSetSavePreview(val:Boolean);
begin
   if val<>FSavePreview then
   begin
      FSavePreview:=Val;
      Owner.FileChanged:=True;
   end;
end;{TFreeProjectSettings.FSetSavePreview}

procedure TFreeProjectSettings.FSetStartDraft(Val:TFloatType);
begin
   if Val<>FStartDraft then
   begin
      FStartdraft:=Val;
      Owner.FileChanged:=True;
   end;
end;{TFreeProjectSettings.FSetStartDraft}

procedure TFreeProjectSettings.FSetTrim(Val:TFloatType);
begin
   if Val<>FTrim then
   begin
      FTrim:=Val;
      Owner.FileChanged:=True;
   end;
end;{TFreeProjectSettings.FSetTrim}

procedure TFreeProjectSettings.FSetEndDraft(Val:TFloatType);
begin
   if Val<>FEndDraft then
   begin
      FEnddraft:=Val;
      Owner.FileChanged:=True;
   end;
end;{TFreeProjectSettings.FSetEndDraft}

procedure TFreeProjectSettings.FSetDraftStep(Val:TFloatType);
begin
   if Val<>FDraftStep then
   begin
      FDraftStep:=Val;
      Owner.FileChanged:=True;
   end;
end;{TFreeProjectSettings.FSetDraftStep}

procedure TFreeProjectSettings.FSetUseDefaultMainframeLocation(Val:Boolean);
begin
   if val<>FUseDefaultMainframeLocation then
   begin
      FUseDefaultMainframeLocation:=Val;
      Owner.FileChanged:=True;
   end;
end;{TFreeProjectSettings.FSetUseDefaultMainframeLocation}

procedure TFreeProjectSettings.FSetProjectName(Val:string);
begin
   if val<>FProjectName then
   begin
      FProjectName:=Val;
      Owner.FileChanged:=true;
   end;
end;{TFreeProjectSettings.FSetProjectName}

procedure TFreeProjectSettings.FSetProjectDesigner(Val:string);
begin
   if val<>FProjectDesigner then
   begin
      FProjectDesigner:=Val;
      Owner.FileChanged:=true;
   end;
end;{TFreeProjectSettings.FSetProjectDesigner}

procedure TFreeProjectSettings.FSetProjectComment(Val:string);
begin
   if val<>FProjectComment then
   begin
      FProjectComment:=Val;
      Owner.FileChanged:=true;
   end;
end;{TFreeProjectSettings.FSetProjectComment}

procedure TFreeProjectSettings.FSetProjectFileCreatedBy(Val:string);
begin
   if val<>FProjectFileCreatedBy then
   begin
      FProjectFileCreatedBy:=Val;
      Owner.FileChanged:=true;
   end;
end;{TFreeProjectSettings.FSetProjectFileCreatedBy}

procedure TFreeProjectSettings.FSetProjectShadeUnderwaterShip(Val:Boolean);
begin
   if val<>FProjectShadeUnderwaterShip then
   begin
      FProjectShadeUnderwaterShip:=Val;
      Owner.FileChanged:=True;
   end;
end;{TFreeProjectSettings.FSetProjectShadeUnderwaterShip}

procedure TFreeProjectSettings.FSetProjectSimplifyIntersections(val:Boolean);
var I:Integer;
begin
   if val<>FProjectSimplifyIntersections then
   begin
      FProjectSimplifyIntersections:=val;
      for I:=1 to Owner.NumberofStations do Owner.Station[I-1].Build:=false;
      for I:=1 to Owner.NumberofButtocks do Owner.Buttock[I-1].Build:=false;
      for I:=1 to Owner.NumberofWaterlines do Owner.Waterline[I-1].Build:=false;
      for I:=1 to Owner.NumberofDiagonals do Owner.Diagonal[I-1].Build:=false;
      for I:=1 to Owner.NumberOfHydrostaticCalculations do Owner.HydrostaticCalculation[I-1].Calculated:=False;
   end;
end;{TFreeProjectSettings.FSetProjectSimplifyIntersections}

procedure TFreeProjectSettings.FSetProjectUnderWaterColor(Val:TColor);
begin
   if Val<>FProjectUnderWaterColor then
   begin
      FProjectUnderWaterColor:=Val;
      Owner.FileChanged:=True;
   end;
end;{TFreeProjectSettings.FSetProjectUnderWaterColor}

procedure TFreeProjectSettings.FSetProjectUnits(Val:TFreeUnitType);
var UnitConversionFactor : double;
    ScaleVector          : T3DCoordinate;
    WeightFactor         : TFloatType;
    ThicknessFactor      : TFloatType;
    I                    : Integer;
    Layer                : TFreeSubdivisionLayer;
begin
   if Val<>FProjectUnits then
   begin
      FProjectUnits:=val;
      if FProjectUnits=fuImperial then
      begin
         // Scale from metric to imperial units
         UnitConversionFactor:=1/0.3048;
         WeightFactor:=WeightConversionFactor;
         ThicknessFactor:=1/25.4;
      end else
      begin
         // scale from imperial to metric units
         UnitConversionFactor:=0.3048;
         WeightFactor:=1/WeightConversionFactor;
         ThicknessFactor:=25.4;
      end;
      FProjectWaterDensity:=FProjectWaterDensity*WeightFactor;
      for I:=1 to Owner.Surface.NumberOfLayers do
      begin
         Layer:=Owner.Surface.Layer[I-1];
         Layer.MaterialDensity:=Layer.MaterialDensity*WeightFactor;
         Layer.Thickness:=Layer.Thickness*ThicknessFactor;
      end;
      ScaleVector.X:=UnitConversionFactor;
      ScaleVector.Y:=UnitConversionFactor;
      ScaleVector.Z:=UnitConversionFactor;
      Owner.Edit.Model_Scale(Scalevector,True,True); // Scale and redraw
   end;
end;{TFreeProjectSettings.FSetProjectUnits}

procedure TFreeProjectSettings.Clear;
begin
   FProjectName:='';
   FProjectDesigner:='';
   FProjectComment:='';
   FProjectFileCreatedBy:='';
   FProjectLength:=1.0;
   FProjectBeam:=1.0;
   FProjectDraft:=1.0;
   FProjectWaterDensity:=1.025;     // 1025 kg/m3 for seawater
   FProjectAppendageCoefficient:=1.0;  // Default 1.0, typical values for ships to cpmpensate for appendices and shellplate = 1.0005;
   FMainparticularsHasBeenset:=False;
   FProjectShadeUnderwaterShip:=True;   // Shades the underwaterpart of the hull in a different color
   FProjectUnderWaterColor:=Owner.Preferences.UnderWaterColor;
   FProjectUnits:=TFreeUnitType(0); // Default is metric units
   FUseDefaultMainframeLocation:=True;
   FProjectMainframeLocation:=0.0;
   FDisableModelCheck:=False;
   FSavePreview:=True;
   FFreeHydrostaticCoefficients:=fcActualData;
   FProjectSimplifyIntersections:=True;
   // hydrostatics settings
   FStartDraft:=0.0;
   FEndDraft:=1.0;
   FDraftStep:=0.1;
   FTrim:=0.0;
   // crosscurves settings
   FNoDisplacements:=0;
   Setlength(FDisplacements,FNoDisplacements);
   FMinimumDisplacement:=0.0;
   FMaximumDisplacement:=1.0;
   FDisplIncrement:=0.1;
   FUseDisplIncrements:=True;
   FNoAngles:=10;
   SetLength(FAngles,FNoAngles);
   FAngles[0]:=0.0;
   FAngles[1]:=2.0;
   FAngles[2]:=5.0;
   FAngles[3]:=10.0;
   FAngles[4]:=15.0;
   FAngles[5]:=20.0;
   FAngles[6]:=30.0;
   FAngles[7]:=40.0;
   FAngles[8]:=50.0;
   FAngles[9]:=60.0;
   FNoStabTrims:=1;
   SetLength(FStabTrims,FNoStabTrims);
   FStabTrims[0]:=0.0;
   FFreeTrim:=True;
   FVCG:=1.0;

end;{TFreeProjectSettings.Clear}

constructor TFreeProjectSettings.Create(Owner:TFreeShip);
begin
   Inherited Create;
   FOwner:=Owner;
   Clear;
end;{TFreeProjectSettings.Create}

// User input of mainparticulars and project setting
procedure TFreeProjectSettings.Edit;
var Dialog : TFreeProjectSettingsDialog;
begin
   Dialog:=TFreeProjectSettingsDialog.Create(Owner);
   Dialog.Edit1.Text:=ProjectName;
   Dialog.UnitBox.ItemIndex:=Ord(ProjectUnits);
   Dialog.Edit7.Text:=ProjectDesigner;
   Dialog.Edit9.Text:=ProjectComment;
   Dialog.Edit10.Text:=ProjectFileCreatedBy;
   Dialog.Length:=ProjectLength;
   Dialog.Beam:=ProjectBeam;
   Dialog.Draft:=ProjectDraft;
   Dialog.Density:=ProjectWaterDensity;
   Dialog.Coefficient:=ProjectAppendageCoefficient;
   Dialog.CheckBox1.Checked:=ProjectShadeUnderwaterShip;
   Dialog.Panel4.Color:=ProjectUnderWaterColor;
   Dialog.Mainframe:=ProjectMainframeLocation;
   Dialog.CheckBox2.Checked:=UseDefaultMainframeLocation;
   Dialog.CheckBox3.Checked:=DisableModelCheck;
   Dialog.CheckBox4.Checked:=SavePreview;
   Dialog.ComboBox1.ItemIndex:=Ord(ProjectCoefficients);

   Dialog.CheckBox5.Checked:=Owner.Visibility.FShowHydrostDisplacement;
   Dialog.CheckBox6.Checked:=Owner.Visibility.FShowHydrostSectionalAreas;
   Dialog.CheckBox7.Checked:=Owner.Visibility.FShowHydrostMetacentricHeight;
   Dialog.CheckBox8.Checked:=Owner.Visibility.FShowHydrostLCF;
   Dialog.CheckBox9.Checked:=Owner.Visibility.FShowHydrostLateralArea;
   Dialog.CheckBox10.Checked:=ProjectSimplifyIntersections;
   ShowTranslatedValues(Dialog);

   if Dialog.Execute then
   begin
      Owner.Edit.CreateUndoObject(Userstring(178),True);
      ProjectName:=Dialog.Edit1.Text;
      ProjectDesigner:=Dialog.Edit7.Text;
      ProjectComment:=Dialog.Edit9.Text;
      ProjectFileCreatedBy:=Dialog.Edit10.Text;
      ProjectUnits:=TFreeUnitType(Dialog.UnitBox.ItemIndex);
      ProjectLength:=Dialog.Length;
      ProjectBeam:=Dialog.Beam;
      ProjectDraft:=Dialog.Draft;
      ProjectWaterDensity:=Dialog.Density;
      ProjectAppendageCoefficient:=Dialog.Coefficient;
      ProjectShadeUnderwaterShip:=Dialog.CheckBox1.Checked;
      ProjectUnderWaterColor:=Dialog.Panel4.Color;
      ProjectMainframeLocation:=Dialog.Mainframe;
      UseDefaultMainframeLocation:=Dialog.CheckBox2.Checked;
      DisableModelCheck:=Dialog.CheckBox3.Checked;
      SavePreview:=Dialog.CheckBox4.Checked;
      ProjectCoefficients:=TFreeHydrostaticCoeff(Dialog.ComboBox1.ItemIndex);

      Owner.Visibility.FShowHydrostDisplacement:=Dialog.CheckBox5.Checked;
      Owner.Visibility.FShowHydrostSectionalAreas:=Dialog.CheckBox6.Checked;
      Owner.Visibility.FShowHydrostMetacentricHeight:=Dialog.CheckBox7.Checked;
      Owner.Visibility.FShowHydrostLCF:=Dialog.CheckBox8.Checked;
      Owner.Visibility.FShowHydrostLateralArea:=Dialog.CheckBox9.Checked;
      ProjectSimplifyIntersections:=Dialog.CheckBox10.Checked;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
   Dialog.Destroy;
end;{TFreeProjectSettings.Edit}

procedure TFreeProjectSettings.LoadBinary(Source:TFreeFilebuffer;Image:TJPegImage);
var I   : Integer;
    Jpg : TJPEGImage;
begin
   Clear;
   Source.Load(FProjectName);
   Source.Load(FProjectDesigner);
   Source.Load(FProjectlength);
   Source.Load(FProjectBeam);
   Source.Load(FProjectDraft);
   Source.Load(FMainparticularsHasBeenset);
   Source.Load(FProjectWaterDensity);
   Source.Load(FProjectAppendageCoefficient);
   Source.Load(FProjectShadeUnderwaterShip);
   Source.Load(FProjectUnderWaterColor);
   Source.Load(I);
   FProjectUnits:=TFreeUnitType(I);
   Source.Load(FUseDefaultMainframeLocation);
   Source.Load(FProjectMainframeLocation);
   Source.Load(FDisableModelCheck);
   Source.Load(FProjectComment);
   Source.Load(FProjectFileCreatedBy);
   FSavePreview:=True;
   if Owner.FileVersion>=fv210 then
   begin
      Source.Load(I);
      FFreeHydrostaticCoefficients:=TFreeHydrostaticCoeff(I);
      Source.Load(FSavePreview);
      if FSavePreview then
      begin
         Jpg:=TJPEGImage.Create;
         Source.Load(Jpg);
         if Image<>nil then Image.Assign(JPG);
         Jpg.Destroy;
      end;
      if Owner.FileVersion>=fv230 then
      begin
          Source.Load(FProjectSimplifyIntersections);
      end;
      if Owner.Fileversion>=fv250 then
      begin
         // save settings for hydrostatics and crosscurves

         // hydrostatics
         Source.Load(FStartdraft);
         Source.Load(FEndDraft);
         Source.Load(FDraftStep);
         Source.Load(FTrim);
         // Crosscurves settings
         Source.Load(FNoDisplacements);
         Setlength(FDisplacements,FNoDisplacements);
         for I:=1 to FNoDisplacements do Source.Load(FDisplacements[I-1]);
         Source.Load(FMinimumDisplacement);
         Source.Load(FMaximumDisplacement);
         Source.Load(FDisplIncrement);
         Source.Load(FUseDisplIncrements);
         Source.Load(FNoAngles);
         Setlength(FAngles,FNoAngles);
         for I:=1 to FNoAngles do Source.Load(FAngles[I-1]);
         Source.Load(FNoStabTrims);
         Setlength(FStabTrims,FNoStabTrims);
         for I:=1 to FNoStabTrims do Source.Load(FStabTrims[I-1]);
         Source.Load(FFreeTrim);
         Source.Load(FVCG);
      end;
   end;
end;{TFreeProjectSettings.LoadBinary}

procedure TFreeProjectSettings.SaveBinary(Destination:TFreeFileBuffer);
var Jpg     : TJPegImage;
    I       : Integer;
begin
   if Owner.FileVersion>=fv120 then
   begin
      Destination.Add(ProjectName);
      Destination.Add(ProjectDesigner);
      Destination.Add(FProjectlength);
      Destination.Add(FProjectBeam);
      Destination.Add(FProjectDraft);
      Destination.Add(FMainparticularsHasBeenset);
      Destination.Add(FProjectWaterDensity);
      Destination.Add(FProjectAppendageCoefficient);
      Destination.Add(FProjectShadeUnderwaterShip);
      Destination.Add(FProjectUnderWaterColor);
      Destination.Add(ord(FProjectUnits));
      if Owner.FileVersion>=fv160 then
      begin
         Destination.Add(FUseDefaultMainframeLocation);
         Destination.Add(FProjectMainframeLocation);
         if Owner.FileVersion>=fv165 then
         begin
            Destination.Add(DisableModelCheck);
         end;
      end;
      Destination.Add(FProjectComment);
      Destination.Add(FProjectFileCreatedBy);
      if Owner.FileVersion>=fv210 then
      begin
         Destination.Add(Ord(ProjectCoefficients));
         Destination.Add(FSavePreview);
         if FSavePreview then
         begin
            Jpg:=Owner.FGetPreview;
            Destination.Add(Jpg);
            Jpg.Destroy;
         end;
         if Owner.FileVersion>=fv230 then
         begin
            Destination.Add(FProjectSimplifyIntersections);
         end;
         if Owner.Fileversion>=fv250 then
         begin
            // save settings for hydrostatics
            Destination.Add(FStartdraft);
            Destination.Add(FEndDraft);
            Destination.Add(FDraftStep);
            Destination.Add(FTrim);
            // Crosscurves settings
            Destination.Add(FNoDisplacements);
            for I:=1 to FNoDisplacements do Destination.Add(FDisplacements[I-1]);
            Destination.Add(FMinimumDisplacement);
            Destination.Add(FMaximumDisplacement);
            Destination.Add(FDisplIncrement);
            Destination.Add(FUseDisplIncrements);
            Destination.Add(FNoAngles);
            for I:=1 to FNoAngles do Destination.Add(FAngles[I-1]);
            Destination.Add(FNoStabTrims);
            for I:=1 to FNoStabTrims do Destination.Add(FStabTrims[I-1]);
            Destination.Add(FFreeTrim);
            Destination.Add(FVCG);
         end;
      end;
   end;
end;{TFreeProjectSettings.SaveBinary}

{---------------------------------------------------------------------------------------------------}
{                                       TFreeShip                                                   }
{                                                                                                   }
{   TFreeShip is the actual component used for modelling and representing the ship                  }
{---------------------------------------------------------------------------------------------------}
function TFreeShip.FGetNumberOfViewports:integer;
begin
   Result:=FViewports.Count;
end;{TFreeShip.FGetNumberOfViewports}

function TFreeShip.FGetOnChangeActiveLayer:TChangeActiveLayerEvent;
begin
   Result:=Surface.OnChangeActiveLayer;
end;{TFreeShip.FGetOnChangeActiveLayer}

function TFreeShip.FGetOnChangeLayerData:TNotifyEvent;
begin
   Result:=Surface.OnChangeLayerData;
end;{TFreeShip.FGetOnChangeLayerData}

function TFreeShip.FGetOnSelectItem:TNotifyEvent;
begin
   Result:=Surface.OnSelectItem;
end;{TFreeShip.FGetOnSelectItem}

function TFreeShip.FGetSelectedControlCurve(Index:integer):TFreeSubdivisionControlCurve;
begin
   Result:=Surface.SelectedControlCurve[index];
end;{TFreeShip.FGetSelectedControlCurve}

function TFreeShip.FGetControlCurve(Index:integer):TFreeSubdivisionControlCurve;
begin
   Result:=Surface.ControlCurve[index];
end;{TFreeShip.FGetControlCurve}

function TFreeShip.FGetSelectedControlEdge(Index:integer):TFreeSubdivisionControlEdge;
begin
   Result:=Surface.SelectedControlEdge[index];
end;{TFreeShip.FGetSelectedControlEdge}

function TFreeShip.FGetSelectedControlPoint(Index:integer):TFreeSubdivisionControlPoint;
begin
   Result:=Surface.SelectedControlPoint[index];
end;{TFreeShip.FGetSelectedControlPoint}

function TFreeShip.FGetSelectedControlFace(Index:integer):TFreeSubdivisionControlFace;
begin
   Result:=Surface.SelectedControlFace[index];
end;{TFreeShip.FGetSelectedControlFace}

function TFreeShip.FGetSelectedFlowline(index:Integer):TFreeFlowline;
begin
   Result:=FSelectedFlowlines[index];
end;{TFreeShip.FGetSelectedFlowline}

function TFreeShip.FGetSelectedMarker(index:Integer):TFreeMarker;
begin
   Result:=FSelectedMarkers[index];
end;{TFreeShip.FGetSelectedMarker}

function TFreeShip.FGetStation(Index:integer):TFreeIntersection;
begin
   if (Index>=0) and (INdex<Fstations.Count) then Result:=FStations[index]
                                             else raise exception.Create('Invalid station-index');
end;{TFreeShip.FGetStation}

function TFreeShip.FGetMarker(Index:integer):TFreeMarker;
begin
   if (Index>=0) and (Index<FMarkers.Count) then Result:=FMarkers[index]
                                            else raise exception.Create('Invalid marker-index');
end;{TFreeShip.FGetMarker}

function TFreeShip.FGetNumberofBackgroundImages:Integer;
begin
  Result:=FBackgroundImages.Count;
end;{TFreeShip.FGetNumberofBackgroundImages}

function TFreeShip.FGetUndoCount:integer;
begin
   Result:=FUndoObjects.Count;
end;{TFreeShip.FGetUndoCount}

function TFreeShip.FGetUndoMemory:integer;
var I:integer;
begin
   result:=0;
   for I:=1 to UndoCount do Result:=Result+UndoObject[I-1].Memory;
end;{TFreeShip.FGetUndoMemory}

function TFreeShip.FGetUndoObject(Index:integer):TFreeUndoObject;
begin
   Result:=FUndoObjects[Index];
end;{TFreeShip.FGetUndoObject}

function TFreeShip.FGetButtock(Index:integer):TFreeIntersection;
begin
   if (Index>=0) and (Index<FButtocks.Count) then Result:=FButtocks[index]
                                             else raise exception.Create('Invalid Buttock-index');
end;{TFreeShip.FGetButtock}

function TFreeShip.FGetDiagonal(Index:integer):TFreeIntersection;
begin
   if (Index>=0) and (Index<FDiagonals.Count) then Result:=FDiagonals[index]
                                              else raise exception.Create('Invalid Diagonal-index');
end;{TFreeShip.FGetDiagonal}

function TFreeShip.FGetFlowline(Index:integer):TFreeFlowline;
begin
   Result:=FFlowlines[index];
end;{TFreeShip.FGetFlowline}

function TFreeShip.FGetWaterline(Index:integer):TFreeIntersection;
begin
   if (Index>=0) and (Index<FWaterlines.Count) then Result:=FWaterlines[index]
                                             else raise exception.Create('Invalid Waterline-index');
end;{TFreeShip.FGetWaterline}

// Assembles all stations and builds a 2D bodyplan for export to other calculating programs
procedure TFreeShip.FBuildValidFrameTable(Destination:TFasterList;CloseAtDeck:Boolean);
var I,J           : integer;
    Intersection  : TFreeIntersection;
    Spline        : TFreeSpline;
    Min           : TFloatType;
    P             : T3DCoordinate;
    TmpList       : TFasterList;
begin
   Min:=0.0;
   for I:=1 to NumberOfStations do
   begin
      Intersection:=Station[I-1];
      if not Intersection.Build then Intersection.Rebuild;
      TmpList:=TFasterList.Create;
      for J:=1 to Intersection.Count do
      begin
         Spline:=TFreeSpline.Create;
         Spline.Assign(Intersection.Items[J-1]);
         // Quick check to determine if the frame runs from bottom to top
         if Spline.Value(0.0).Z>Spline.Value(1.0).Z then
         begin
            // If not then reverse the points
            Spline.InvertDirection;
         end;
         TmpList.Add(Spline);
      end;
      // Take all segments and join into one
      if TmpList.Count>1 then
      begin
         JoinSplineSegments(0.01,True,TmpList);
      end;
      for J:=1 to TmpList.Count do
      begin
         Spline:=TmpList[J-1];
         if CloseAtDeck then
         begin
            if Spline.Point[Spline.NumberOfPoints-1].Y<>0.0 then
            begin
               P:=Spline.Point[Spline.NumberOfPoints-1];
               P.Y:=0.0;
               Spline.Add(P);
               Spline.Knuckle[Spline.NumberOfPoints-2]:=True;
            end;
         end;
         Destination.Add(Spline);
         if I=1 then Min:=Spline.Min.Z
                else if Spline.Min.Z<Min then Min:=Spline.Min.Z;
      end;
      Tmplist.Destroy;
   end;
   // Now shift all stations up or down so that the lowest point
   // of all stations is on the baseline z=0.0
   if Min<>0.0 then for I:=1 to Destination.Count do
   begin
      Spline:=Destination[I-1];
      for J:=1 to Spline.NumberOfPoints do
      begin
         P:=Spline.Point[J-1];
         P.Z:=P.Z-Min;
         Spline.Point[J-1]:=P;
      end;
   end;
end;{TFreeShip.FBuildValidFrameTable}

function TFreeShip.FGetActiveLayer:TFreeSubdivisionlayer;
begin
   Result:=Surface.ActiveLayer;
end;{TFreeShip.FGetActiveLayer}

function TFreeShip.FGetBackgroundImage(Index:Integer):TFreeBackgroundImageData;
begin
   Result:=FBackgroundImages[index];
end;{TFreeShip.FGetBackgroundImage}

function TFreeShip.FGetBuild:Boolean;
begin
   Result:=Surface.Build;
end;{TFreeShip.FGetBuild}

function TFreeShip.FGetFilename:string;
begin
   if FFilename='' then FFilename:=Userstring(179);
   Result:=ChangeFileExt(FFilename,FreeShipExtention);
end;{TFreeShip.FGetFilename}

function TFreeShip.FGetHydrostaticCalculation(Index:integer):TFreeHydrostaticCalc;
begin
   Result:=FHydrostaticCalculations[index];
end;{TFreeShip.FGetHydrostaticCalculation}

function TFreeShip.FGetLayer(Index:integer):TFreeSubdivisionLayer;
begin
   Result:=Surface.Layer[index];
end;{TFreeShip.FGetLayer}

function TFreeShip.FGetNumberOfMarkers:integer;
begin
   Result:=FMarkers.Count;
end;{TFreeShip.FGetNumberOfMarkers}

function TFreeShip.FGetNumberOfStations:integer;
begin
   Result:=FStations.Count;
end;{TFreeShip.FGetNumberOfStations}

function TFreeShip.FGetNumberOfWaterlines:integer;
begin
   Result:=FWaterlines.Count;
end;{TFreeShip.FGetNumberOfWaterlines}

function TFreeShip.FGetNumberOfButtocks:integer;
begin
   Result:=FButtocks.Count;
end;{TFreeShip.FGetNumberOfButtocks}

function TFreeShip.FGetNumberOfDiagonals:integer;
begin
   Result:=FDiagonals.Count;
end;{TFreeShip.FGetNumberOfDiagonals}

function TFreeShip.FGetNumberOfFlowLines:Integer;
begin
   Result:=FFlowlines.Count;
end;{TFreeShip.FGetNumberOfFlowLines}

function TFreeShip.FGetNumberOfHydrostaticCalculations:integer;
begin
   Result:=FHydrostaticCalculations.Count;
end;{TFreeShip.FGetNumberOfHydrostaticCalculations}

function TFreeShip.FGetNumberOfLockedPoints:Integer;
begin
   Result:=Surface.NumberOfLockedPoints;
end;{TFreeShip.FGetNumberOfLockedPoints}

function TFreeShip.FGetNumberOfLayers:integer;
begin
   Result:=Surface.NumberOfLayers;
end;{TFreeShip.FGetNumberOfLayers}

function TFreeShip.FGetViewport(Index:integer):TFreeViewport;
begin
   if (Index>=0) and (Index<NumberOfViewports) then Result:=FViewports[index]
                                               else Raise Exception.Create('Invalid viewport index!');
end;{TFreeShip.FGetViewport}

procedure TFreeShip.FSetActiveControlPoint(Val:TFreeSubdivisionControlPoint);
begin
   if Val<>FActiveControlPoint then
   begin
      FActiveControlPoint:=Val;
      FControlpointForm.ActiveControlPoint:=FActiveControlPoint;
      if FActiveControlPoint=nil then
      begin
         ShowTranslatedValues(FControlpointForm);
         if FControlpointForm.Visible then FControlpointForm.Visible:=False;
      end else
      begin
         // The first line makes sure that the activecontrolpoint form does NOT recieve focus.
         // because the mousewheel zoom in/out doesn't work anymore in that case
         if not FControlpointForm.Visible then
         begin
            ShowTranslatedValues(FControlpointForm);
            ShowWindow(FControlpointForm.Handle, SW_SHOWNOACTIVATE);
         end;
         if not FControlpointForm.Visible then FControlpointForm.Visible:=true;
      end;
      FCurrentlyMoving:=False;
      FPointHasBeenMoved:=False;
   end else if FActiveControlPoint<>nil then
   begin
      // Update controlpoint information
      FControlpointForm.ActiveControlPoint:=FActiveControlPoint;
   end;
end;{TFreeShip.FSetActiveControlPoint}

procedure TFreeShip.FSetActiveLayer(Val:TFreeSubdivisionLayer);
begin
   Surface.ActiveLayer:=Val;
end;{TFreeShip.FSetActiveLayer}

procedure TFreeShip.FSetBuild(Val:Boolean);
var I : integer;
begin
   Surface.Build:=Val;
   if not Build then
   begin
      for I:=1 to NumberOfStations do Station[I-1].Build:=False;
      for I:=1 to NumberOfButtocks do Buttock[I-1].Build:=False;
      for I:=1 to NumberOfWaterlines do Waterline[I-1].Build:=False;
      for I:=1 to NumberOfDiagonals do Diagonal[I-1].Build:=False;
      for I:=1 to NumberOfHydrostaticCalculations do HydrostaticCalculation[I-1].Calculated:=False;
      for I:=1to NumberOfFlowlines do Flowline[I-1].Build:=False;
   end;
end;{TFreeShip.FSetBuild}

procedure TFreeShip.FSetEditMode(Val:TFreeEditMode);
begin
   if Val<>FEditMode then
   begin
      FEditMode:=Val;
      Case EditMode of
         emSelectItems      : begin
                              end;
      end;
      Redraw;
   end;
end;{TFreeShip.FSetEditMode}

procedure TFreeShip.FSetFileChanged(Val:Boolean);
begin
   if Val<>FFileChanged then
   begin
      FFileChanged:=Val;
      if assigned(FOnFileChanged) then FOnFileChanged(self);
   end;
end;{TFreeShip.FSetFileChanged}

procedure TFreeShip.FSetFileName(Val:string);
var Tmp:string;
begin
    if val='' then val:=Userstring(179);
    Tmp:=ChangeFileExt(Val,FreeShipExtention);
    if FFilename<>val then
    begin
       FFilename:=Val;
    end;
end;{TFreeShip.FSetFileName}

procedure TFreeShip.FSetFileVersion(Val:TFreeFileVersion);
begin
   if Val<>FFileVersion then
   begin
      FFileVersion:=Val;
      FileChanged:=true;
   end;
end;{TFreeShip.FSetFileVersion}

function TFreeShip.FGetNumberOfSelectedControlEdges:integer;
begin
   Result:=Surface.NumberOfSelectedControlEdges;
end;{TFreeShip.FGetNumberOfSelectedControlEdges}

function TFreeShip.FGetNumberOfSelectedControlCurves:integer;
begin
   Result:=Surface.NumberOfSelectedControlCurves;
end;{TFreeShip.FGetNumberOfSelectedControlCurves}

function TFreeShip.FGetNumberOfControlCurves:integer;
begin
   Result:=Surface.NumberOfControlCurves;
end;{TFreeShip.FGetNumberOfControlCurves}

function TFreeShip.FGetNumberOfSelectedControlFaces:integer;
begin
   Result:=Surface.NumberOfSelectedControlFaces;
end;{TFreeShip.FGetNumberOfSelectedControlFaces}

function TFreeShip.FGetNumberOfSelectedControlPoints:integer;
begin
   Result:=Surface.NumberOfSelectedControlPoints;
end;{TFreeShip.FGetNumberOfSelectedControlPoints}

function TFreeShip.FGetNumberOfselectedFlowlines:Integer;
begin
   Result:=FselectedFlowlines.Count;
end;{TFreeShip.FGetNumberOfselectedFlowlines}

function TFreeShip.FGetNumberOfselectedMarkers:Integer;
begin
   Result:=FselectedMarkers.Count;
end;{TFreeShip.FGetNumberOfselectedMarkers}

function TFreeShip.FGetNumberOfSelectedLockedPoints:integer;
begin
   Result:=Surface.NumberOfSelectedLockedPoints;
end;{TFreeShip.FGetNumberOfSelectedLockedPoints}

procedure TFreeShip.FSetOnChangeActiveLayer(val:TChangeActiveLayerEvent);
begin
   Surface.OnChangeActiveLayer:=val;
end;{TFreeShip.FSetOnChangeActiveLayer}

procedure TFreeShip.FSetOnChangeLayerData(Val:TNotifyEvent);
begin
   Surface.OnChangeLayerData:=Val;
   if Assigned(OnChangeLayerData) then OnChangeLayerData;
end;{TFreeShip.FSetOnChangeLayerData}

procedure TFreeShip.FSetOnSelectItem(Val:TNotifyEvent);
begin
   Surface.OnSelectItem:=Val;
end;{TFreeShip.FSetOnSelectItem}

procedure TFreeShip.FSetPrecision(Val:TFreePrecisionType);
begin
   if Val<>FPrecision then
   begin
      FPrecision:=Val;
      Surface.DesiredSubdivisionLevel:=Ord(Precision)+1;
      FileChanged:=True;
      Build:=False;
      Redraw;
   end;
end;{TFreeShip.FSetPrecision}

function TFreeShip.FGetPreview:TJPEGImage;

   procedure Resample1(var source,Target:TBitmap;Width,Height:integer);
   var I,J,W,H       : Integer;
       Row1,Row2     : integer;
       Col1,Col2     : integer;
       U,V,S,T       : TFloatType;
       R1,G1,B1      : TFloatType;
       R2,G2,B2      : TFloatType;
       DestPix       : pRGBTripleArray;
       SourceRow1    : pRGBTripleArray;
       SourceRow2    : pRGBTripleArray;
   begin
      W:=Width-1;
      H:=Height-1;
      if Target.Width<>Width then Target.Width:=Width;
      if Target.Height<>Height then Target.Height:=Height;
      for I:=0 to H do
      begin
         u:=I/H;
         S:=u*(Source.Height-1);
         Row1:=trunc(S);
         if Row1<0 then Row1:=0 else if Row1>Source.Height-2 then Row1:=Source.Height-2;
         Row2:=Row1+1;
         S:=(S-Row1)/(Row2-Row1);

         DestPix:=Target.ScanLine[I];
         SourceRow1:=Source.ScanLine[Row1];
         SourceRow2:=Source.ScanLine[Row2];
         for J:=0 to W-1 do
         begin
            V:=J/W;
            T:=V*(Source.Width-1);
            Col1:=Trunc(T);
            if Col1<0 then Col1:=0 else if Col1>Source.Width-2 then Col1:=Source.Width-2;
            Col2:=Col1+1;
            T:=(T-Col1)/(Col2-Col1);
            R1:=SourceRow1^[Col1].rgbtRed+S*(SourceRow2^[Col1].rgbtRed-SourceRow1^[Col1].rgbtRed);
            G1:=SourceRow1^[Col1].rgbtGreen+S*(SourceRow2^[Col1].rgbtGreen-SourceRow1^[Col1].rgbtGreen);
            B1:=SourceRow1^[Col1].rgbtBlue+S*(SourceRow2^[Col1].rgbtBlue-SourceRow1^[Col1].rgbtBlue);
            R2:=SourceRow1^[Col2].rgbtRed+S*(SourceRow2^[Col2].rgbtRed-SourceRow1^[Col2].rgbtRed);
            G2:=SourceRow1^[Col2].rgbtGreen+S*(SourceRow2^[Col2].rgbtGreen-SourceRow1^[Col2].rgbtGreen);
            B2:=SourceRow1^[Col2].rgbtBlue+S*(SourceRow2^[Col2].rgbtBlue-SourceRow1^[Col2].rgbtBlue);
            DestPix^[J].rgbtRed:=Round(R1+T*(R2-R1));
            DestPix^[J].rgbtgreen:=Round(G1+T*(G2-G1));
            DestPix^[J].rgbtBlue:=Round(B1+T*(B2-B1));
         end;
      end;
   end;{Resample}

   procedure Resample(var source,Target:TBitmap;Width,Height:integer);
   var Bmp1       : TBitmap;
       I,J        : Integer;
       Row1,Row2  : pRGBTripleArray;
   begin
      Bmp1:=TBitmap.Create;
      Bmp1.PixelFormat:=pf24bit;
      Resample1(Source,Bmp1,Width,Height);
      Target.PixelFormat:=pf24bit;
      if Target.Width<>Width then Target.Width:=Width;
      if Target.Height<>Height then Target.Height:=Height;

      StretchBlt(Target.Canvas.Handle,0,0,Target.Width,Target.Height,
                 Source.Canvas.Handle,0,0,Source.Width,Source.Height,SRCCOPY);

      // interpolate between the two images to get the best interpolation
      for I:=1 to Target.Height do
      begin
         Row1:=Bmp1.ScanLine[I-1];
         Row2:=Target.ScanLine[I-1];
         for J:=0 to Target.Width-1 do
         begin
            Row2^[J].rgbtRed:=  (4*Row1^[J].rgbtRed  +Row2^[J].rgbtRed) div 5;
            Row2^[J].rgbtGreen:=(4*Row1^[J].rgbtGreen+Row2^[J].rgbtGreen) div 5;
            Row2^[J].rgbtBlue:= (4*Row1^[J].rgbtBlue +Row2^[J].rgbtBlue) div 5;
         end;
      end;
      Bmp1.Destroy;
   end;{Resample}

   Procedure SnapShot(xpos: integer; ypos: integer;OrgWidth,OrgHeight:integer; Var Bmp:TBitmap);
   const DesW = 400;
         DesH = 300;
   Var dc      : HDC;
       lpPal   : PLOGPALETTE;
       W,H     : Integer;
       TmpBmp  : TBitmap;
   Begin
      TmpBmp:=TBitmap.Create;
      TmpBmp.PixelFormat:=pf24bit;
      If ((OrgWidth=0) Or (OrgHeight = 0)) Then exit;
      TmpBmp.Width:=OrgWidth;
      TmpBmp.Height:=OrgHeight;
      dc := GetDc(0);
      If (dc = 0) Then exit;
      If (GetDeviceCaps(dc, RASTERCAPS) And RC_PALETTE = RC_PALETTE) Then
      Begin
         GetMem(lpPal, sizeof(TLOGPALETTE) + (255 * sizeof(TPALETTEENTRY)));
         FillChar(lpPal^, sizeof(TLOGPALETTE) + (255 * sizeof(TPALETTEENTRY)), #0);
         lpPal^.palVersion := $300;
         lpPal^.palNumEntries := GetSystemPaletteEntries(dc, 0, 256, lpPal^.palPalEntry);
         If (lpPal^.PalNumEntries <> 0) Then TmpBmp.Palette := CreatePalette(lpPal^);
         FreeMem(lpPal, sizeof(TLOGPALETTE) + (255 * sizeof(TPALETTEENTRY)));
      End;
      BitBlt(TmpBmp.Canvas.Handle,0,0,OrgWidth,OrgHeight,Dc,xpos,ypos,SRCCOPY);
      if OrgWidth/OrgHeight>4/3 then
      begin
         W:=DesW;
         H:=round(W*OrgHeight/OrgWidth);
      end else
      begin
         H:=DesH;
         W:=Round(H*OrgWidth/OrgHeight);
      end;
      Resample(TmpBmp,Bmp,W,H);
      ReleaseDc(0, dc);
      TmpBmp.Destroy;
   End;{SnapShot}

var Tmp:TBitmap;
begin
   Tmp:=TBitmap.create;
   Tmp.PixelFormat:=pf24bit;
   Snapshot(Application.MainForm.Left,
            Application.MainForm.Top,
            Application.MainForm.Width,
            Application.MainForm.Height,Tmp);
   Result:=TJPEGImage.Create;
   Result.Assign(Tmp);
   Result.CompressionQuality:=90;
   //Result.SaveToFile('c:\test.jpg');
   Tmp.Destroy;
end;{TFreeShip.FGetPreview}

procedure TFreeShip.AddViewport(Viewport:TFreeViewport);
// Add a viewport to the list of viewports connected to the model
begin
   if FViewports.IndexOf(Viewport)=-1 then
   begin
      Viewport.Color:=Preferences.ViewportColor;
      FViewports.Add(Viewport);
      Viewport.ZoomExtents;
   end;
end;{TFreeShip.AddViewport}

function TFreeShip.AdjustMarkers:Boolean;
begin
   Result:=False;
   if NumberofMarkers>0 then
   begin
      Result:=MessageDlg(Userstring(180)+'?',mtInformation,[mbYes,mbNo],0)=mrYes;
   end;
end;{TFreeShip.AdjustMarkers}

constructor TFreeShip.Create(AOwner:TComponent);
begin
   Inherited Create(AOwner);
   FIntersectionDialog:=TFreeIntersectionDialog.Create(self);
   FEdit:=TFreeEdit.Create(Self);
   FPreferences:=TFreePreferences.Create(self);
   FPreferences.Load;
   FProjectSettings:=TFreeProjectSettings.Create(self);
   FFileVersion:=CurrentVersion;
   FActiveControlPoint:=nil;
   FSurface:=TFreeSubdivisionSurface.Create;
   FSurface.LayerColor:=FPreferences.LayerColor;
   FViewports:=TFasterList.Create;
   FMarkers:=TFasterList.Create;
   FVisibility:=TFreeVisibility.Create(self);
   FStations:=TFasterList.Create;
   FButtocks:=TFasterList.Create;
   FWaterlines:=TFasterList.Create;
   FDiagonals:=TFasterList.Create;
   FHydrostaticCalculations:=TFasterList.Create;
   FUndoObjects:=TFasterList.Create;
   FBackgroundImages:=TFasterList.Create;
   FFlowLines:=TFasterList.Create;
   FSelectedFlowlines:=TFasterList.Create;
   FSelectedMarkers:=TFasterList.Create;
   FDesignHydrostatics:=TFreeHydrostaticCalc.Create(self);
   ClearUndo;
   Clear;
   FControlpointForm:=TFreeControlPointForm.Create(Self);
   FControlpointForm.FreeShip:=self;
end;{TFreeShip.Create}

procedure TFreeShip.CreateOutputHeader(CalcHeader:string;Strings:TStrings);
const Separator = #32;
begin
   Strings.Add('');
   Strings.Add(CalcHeader);
   Strings.Add('');
   Strings.Add(Makelength(Userstring(39),21)+' : '+Separator+ProjectSettings.ProjectName);
   Strings.Add(Makelength(Userstring(40),21)+' : '+Separator+ProjectSettings.ProjectDesigner);
   if ProjectSettings.ProjectFileCreatedBy<>'' then Strings.Add(Makelength(Userstring(41),21)+' : '+Separator+ProjectSettings.ProjectFileCreatedBy);
   if ProjectSettings.ProjectComment<>'' then Strings.Add(Makelength(Userstring(42),21)+' : '+Separator+ProjectSettings.ProjectComment);
   Strings.Add(Makelength(Userstring(43),21)+' : '+Separator+Filename);
   Strings.Add('');
   if ProjectSettings.MainparticularsHasBeenset then
   begin
      Strings.Add(MakeLength(Userstring(44),21)+' : '+MakeLength(ProjectSettings.ProjectLength,-1,10)+#32+LengthStr(ProjectSettings.ProjectUnits));
      Strings.Add(MakeLength(Userstring(46),21)+' : '+MakeLength(ProjectSettings.ProjectBeam,-1,10)+#32+LengthStr(ProjectSettings.ProjectUnits));
      Strings.Add(MakeLength(Userstring(48),21)+' : '+MakeLength(ProjectSettings.Projectdraft,-1,10)+#32+LengthStr(ProjectSettings.ProjectUnits));
      Strings.Add(MakeLength(Userstring(49),21)+' : '+MakeLength(ProjectSettings.ProjectMainframeLocation,-1,10)+#32+LengthStr(ProjectSettings.ProjectUnits));
      Strings.Add(MakeLength(Userstring(50),21)+' : '+MakeLength(ProjectSettings.ProjectWaterDensity,3,10)+#32+DensityStr(ProjectSettings.ProjectUnits));
      Strings.Add(MakeLength(Userstring(51),21)+' : '+MakeLength(ProjectSettings.ProjectAppendageCoefficient,4,10));
      Strings.Add('');
   end;
   Strings.Add(Makelength(Userstring(181),9)+' : '+DateToStr(Date));
   Strings.Add(Makelength(Userstring(182),9)+' : '+TimeToStr(Time));
   Strings.Add('');
end;{TFreeShip.CreateOutputHeader}

procedure TFreeShip.DeleteViewport(Viewport:TFreeViewport);
var Index:integer;
begin
   Index:=FViewports.IndexOf(Viewport);
   if Index<>-1 then FViewports.Delete(index);
end;{TFreeShip.DeleteViewport}

procedure TFreeShip.Clear;
var I : integer;
    Pt:TPoint;
begin
   // Initialize all data
   FPrecision:=fpLow;
   FFileVersion:=CurrentVersion;
   FFileChanged:=False;
   FSurface.Clear;
   FFilename:=Userstring(179);
   FVisibility.Clear;
   FEditMode:=emSelectItems;// Set editmode to select items
   ActiveControlPoint:=nil;
   // delete Markers
   for I:=1 to NumberOfMarkers do Marker[I-1].Destroy;
   FMarkers.Clear;
   FSelectedMarkers.Clear;
   // delete stations
   for I:=1 to NumberOfStations do Station[I-1].Destroy;
   FStations.Clear;
   // delete Buttocks
   for I:=1 to NumberOfButtocks do Buttock[I-1].Destroy;
   FButtocks.Clear;
   // delete Waterlines
   for I:=1 to NumberOfWaterlines do Waterline[I-1].Destroy;
   FWaterlines.Clear;
   // delete Diagonals
   for I:=1 to NumberOfDiagonals do Diagonal[I-1].Destroy;
   for I:=1 to NumberOfHydrostaticCalculations do HydrostaticCalculation[I-1].Calculated:=false;
   FDiagonals.Clear;
   FProjectSettings.Clear;
   FFilenameSet:=False;
   FStopAskingForFileVersion:=False;
   Fillchar(FResistanceDelftData,SizeOf(FResistanceDelftData),0);
   Fillchar(FResistanceKaperData,SizeOf(TFreeKAPERResistanceData),0);
   // Delete backgroundimages
   for I:=1 to NumberofBackgroundImages do BackgroundImage[I-1].Destroy;
   FBackGroundImages.Clear;
   // Clear flowlines
   for I:=1 to NumberOfFlowlines do Flowline[I-1].Destroy;
   FFlowlines.clear;
   FSelectedFlowlines.Clear;

   if not (csDestroying in componentState) then
   begin
      // remove backgroundimages from viewports
      Pt.X:=0;
      Pt.Y:=0;
      for I:=1 to NumberOfViewports do
      begin
         Viewport[I-1].BackgroundImage.AssignData(nil,fvPerspective,Pt,1.0,False,clBlack,255,100,3,True);
      end;

      if assigned(FOnFileChanged) then FOnFileChanged(self);
      if Assigned(OnUpdateGeometryInfo) then OnUpdateGeometryInfo(self);
   end;
end;{TFreeShip.Clear}

procedure TFreeShip.ClearUndo;
var I : integer;
begin
   // clear undo
   for I:=1 to UndoCount do UndoObject[I-1].Destroy;
   FUndoObjects.Clear;
   FUndoPosition:=0;
   FPreviousUndoPosition:=FUndoPosition-1;
   if not (csdestroying in componentstate) then if Assigned(FOnUpdateUndoData) then FOnUpdateUndoData(self);
end;{TFreeShip.ClearUndo}

destructor TFreeShip.Destroy;
begin
   Clear;
   ClearUndo;
   FControlpointForm.Destroy;
   FMarkers.Destroy;
   FStations.Destroy;
   FButtocks.Destroy;
   FWaterlines.Destroy;
   FDiagonals.Destroy;
   FVisibility.Destroy;
   FViewports.Destroy;
   FSurface.Destroy;
   FEdit.Destroy;
   FProjectSettings.Destroy;
   FDesignHydrostatics.Destroy;
   FHydrostaticCalculations.Destroy;
   FUndoObjects.Destroy;
   FPreferences.Destroy;
   FIntersectionDialog.Destroy;
   FBackgroundImages.Destroy;
   FFlowlines.Destroy;
   FSelectedFlowlines.Destroy;
   FSelectedMarkers.Destroy;
   Inherited Destroy;
end;{TFreeShip.Destroy}

procedure TFreeShip.Draw;
var I : integer;
begin
   // Redraws model to all viewports by re-initializing all viewports
   For I:=1 to NumberOfViewports do Viewport[I-1].ZoomExtents;
   if LinesplanFrame<>nil then
   begin
      TFreeLinesplanframe(LinesplanFrame).Viewport.ZoomExtents;
   end;
end;{TFreeShip.Draw}

procedure TFreeShip.DrawToViewport(Viewport:TFreeViewport);
var I,Size        : integer;
    Plane         : T3DPlane;
    Curve         : TFreeSpline;
    P             : T3DCoordinate;
    Pt            : TPoint;
    Str           : string;
    LegendHeight  : Integer;
    LegendWidth   : Integer;
    Rect          : TRect;
    RectHeight    : Integer;
    Nrect,NDecimal: Integer;
    R,G,B         : Byte;
    Tmp           : TFloatType;

    procedure DrawPoint(P:T3DCoordinate;Text:string;CompensateHeight:boolean);
    var Pt    : TPoint;
        Size  : Integer;
    begin
      if CompensateHeight then P.Z:=P.Z+FDesignHydrostatics.FData.ModelMin.Z;
      Pt:=Viewport.Project(P);
      Viewport.FontName:='Arial';
      Viewport.FontColor:=Preferences.HydrostaticsFontColor;
      size:=Round(Sqrt(Viewport.Zoom)*7);
      if size<2 then size:=2;
      Viewport.FontSize:=size;
      Size:=Round(Sqrt(Viewport.Zoom)*(Preferences.PointSize+1));
      if size<1 then size:=1;
      Viewport.BrushStyle:=bsClear;
      if Viewport.Printing then Size:=round(Size*Viewport.PrintResolution/150);
      Viewport.PenColor:=clDkGray;//Black;
      Viewport.BrushColor:=clWhite;
      Viewport.BrushStyle:=bsSolid;
      // Draw entire circle in white;
      Viewport.DrawingCanvas.Ellipse(Pt.X-Size,Pt.Y-Size,Pt.X+Size,Pt.Y+Size);
      // Draw upper left part in black
      Viewport.BrushColor:=clBlack;
      Viewport.DrawingCanvas.Pie(Pt.X-Size,Pt.Y-Size,Pt.X+Size,Pt.Y+Size,Pt.X-1,Pt.Y-Size,Pt.X-Size,Pt.Y-1);
      // Draw lower right part in black
      Viewport.DrawingCanvas.Pie(Pt.X-Size,Pt.Y-Size,Pt.X+Size,Pt.Y+Size,Pt.X-1,Pt.Y+Size,Pt.X+Size,Pt.Y-1);
      Viewport.BrushStyle:=bsClear;
      Viewport.DrawingCanvas.TextOut(Pt.X+2*size,Pt.Y,Text);
    end;{DrawPoint}

    procedure DrawGrid;
    var DrawStations    : Boolean;
        DrawButtocks    : Boolean;
        DrawWaterlines  : Boolean;
        DrawDiagonals   : Boolean;
        Min,Max         : T3DCoordinate;
        Position        : TFloatType;
        I,J,N           : integer;
        Height,Width    : integer;
        P1,P2,Diff      : T3DCoordinate;
        Pt1,Pt2         : TPoint;
        Str             : string;
        Pts             : array of TPoint;

        procedure SetFontHeight(DesiredHeight:TFloatType);
        var Height         : TFloatType;
            CurrentHeight  : integer;
        begin
           // Sets the fontheight to a height in modelspace
           Height:=DesiredHeight*Viewport.Scale*Viewport.Zoom;
           Viewport.DrawingCanvas.Font.Size:=8;
           CurrentHeight:=Viewport.DrawingCanvas.TextHeight('X');
           while CurrentHeight>Height do
           begin
              Viewport.DrawingCanvas.Font.Size:=Viewport.DrawingCanvas.Font.Size-1;
              CurrentHeight:=Viewport.DrawingCanvas.TextHeight('X');
              if Viewport.DrawingCanvas.Font.Size<4 then break;
           end;
        end;{SetFontHeight}

    begin
       DrawStations:=Viewport.ViewType<>fvBodyplan;
       DrawButtocks:=Viewport.ViewType<>fvProfile;
       DrawWaterlines:=Viewport.ViewType<>fvPlan;
       DrawDiagonals:=Viewport.ViewType=fvBodyplan;
       // Blowup the boundary box by 3%
       Diff:=ScalePoint(0.03,Subtract(Viewport.Max3D,Viewport.Min3D));
       Min:=Subtract(Viewport.Min3D,Diff);
       Diff:=ScalePoint(-1.0,Diff);
       Max:=Subtract(Viewport.Max3D,diff);
       if DrawStations or DrawButtocks or DrawWaterlines or DrawDiagonals then
       begin
          Viewport.PenColor:=Preferences.GridColor;
          Viewport.FontName:='Arial';
          Viewport.FontColor:=Preferences.GridFontColor;
          // calculate and set fontheight
          SetFontHeight(DistPP3D(Min,Max)/FontheightFactor);
          Height:=Viewport.DrawingCanvas.TextHeight('X');
          Viewport.BrushStyle:=bsClear;
          // draw centerline
          if Viewport.ViewType<>fvProfile then
          begin
             Viewport.FontColor:=clRed;
             Viewport.PenWidth:=2;
             P1:=Min;
             P2:=Max;
             Str:=Userstring(183);
             P1.Y:=0.0;
             P2.Y:=P1.Y;
             Pt1:=Viewport.Project(P1);
             Pt2:=Viewport.Project(P2);
             Viewport.DrawingCanvas.MoveTo(Pt1.X,Pt1.Y);
             Viewport.DrawingCanvas.LineTo(Pt2.X,Pt2.Y);
             Width:=Viewport.DrawingCanvas.TextWidth(Str);
             if Viewport.ViewType=fvBodyplan then
             begin
                Viewport.DrawingCanvas.TextOut(Pt1.X-Width div 2,Pt1.Y,str);
                Viewport.DrawingCanvas.TextOut(Pt2.X-width div 2,Pt2.Y-Height,Str);
             end else
             begin
               Viewport.DrawingCanvas.TextOut(Pt1.X-Width,Pt1.Y-Height,str);
               Viewport.DrawingCanvas.TextOut(Pt2.X,Pt2.Y-Height,Str);
             end;
             Viewport.PenWidth:=1;
             Viewport.FontColor:=Preferences.GridFontColor;
          end;
          if Viewport.Viewtype<>fvPlan then
          begin
             Viewport.FontColor:=clRed;
             // Draw baseline
             Viewport.PenWidth:=2;
             P1:=Min;
             P2:=Max;
             Position:=Surface.Min.Z;
             Str:=Userstring(184)+#32+ConvertDimension(Position,ProjectSettings.ProjectUnits);
             P1.Z:=Position;
             P2.Z:=P1.Z;
             Pt1:=Viewport.Project(P1);
             Pt2:=Viewport.Project(P2);
             Viewport.DrawingCanvas.MoveTo(Pt1.X,Pt1.Y);
             Viewport.DrawingCanvas.LineTo(Pt2.X,Pt2.Y);
             Width:=Viewport.DrawingCanvas.TextWidth(Str);
             Viewport.DrawingCanvas.TextOut(Pt1.X,Pt1.Y-Height,Str);
             Viewport.DrawingCanvas.TextOut(Pt2.X-Width,Pt2.Y-Height,str);
             // Draw dwl
             if ProjectSettings.FMainparticularsHasBeenset then
             begin
                P1:=Min;
                P2:=Max;
                Position:=Surface.Min.Z+ProjectSettings.FProjectDraft;
                Str:=Userstring(185)+#32+ConvertDimension(Position,ProjectSettings.ProjectUnits);
                P1.Z:=Position;
                P2.Z:=P1.Z;
                Pt1:=Viewport.Project(P1);
                Pt2:=Viewport.Project(P2);
                Viewport.DrawingCanvas.MoveTo(Pt1.X,Pt1.Y);
                Viewport.DrawingCanvas.LineTo(Pt2.X,Pt2.Y);
                Width:=Viewport.DrawingCanvas.TextWidth(Str);
                Viewport.DrawingCanvas.TextOut(Pt1.X-width div 2,Pt1.Y-Height,Str);
                Viewport.DrawingCanvas.TextOut(Pt2.X-Width div 2,Pt2.Y-Height,str);
             end;
             Viewport.PenWidth:=1;
             Viewport.FontColor:=Preferences.GridFontColor;
          end;
          if DrawStations then
          begin
             P1:=Min;
             P2:=Max;
             for I:=1 to self.NumberofStations do
             begin
                Position:=-Station[I-1].Plane.d;
                Str:=ConvertDimension(Position,ProjectSettings.ProjectUnits);
                P1.X:=Position;
                P2.X:=P1.X;
                Pt1:=Viewport.Project(P1);
                Pt2:=Viewport.Project(P2);
                Viewport.DrawingCanvas.MoveTo(Pt1.X,Pt1.Y);
                Viewport.DrawingCanvas.LineTo(Pt2.X,Pt2.Y);
                Viewport.DrawingCanvas.TextOut(Pt1.X,Pt1.Y,Str);
                Viewport.DrawingCanvas.TextOut(Pt2.X,Pt2.Y-Height,Str);
             end;
          end;
          if DrawDiagonals then
          begin
             Setlength(Pts,101);
             Viewport.PenWidth:=1;
             for I:=1 to NumberOfDiagonals do
             begin
                if not Diagonal[I-1].Build then Diagonal[I-1].Rebuild;
                for J:=1 to Diagonal[I-1].Count do
                begin
                   for N:=0 to 100 do
                   begin
                      P1:=Diagonal[I-1].Items[J-1].Value(N/100);
                      Pts[N]:=Viewport.Project(P1);
                   end;
                   Viewport.DrawingCanvas.Polyline(Pts);
                   if (Visibility.ModelView=mvBoth) or (Viewport.ViewType=fvBodyplan) then
                   begin
                      for N:=0 to 100 do
                      begin
                         P1:=Diagonal[I-1].Items[J-1].Value(N/100);
                         P1.Y:=-P1.Y;
                         Pts[N]:=Viewport.Project(P1);
                      end;
                      Viewport.DrawingCanvas.Polyline(Pts);
                   end;
                end;
             end;
          end;
          if DrawButtocks then
          begin
             P1:=Min;
             P2:=Max;
             for I:=1 to self.NumberofButtocks do
             begin
                Position:=-Buttock[I-1].Plane.d;
                Str:=ConvertDimension(Position,ProjectSettings.ProjectUnits);
                P1.Y:=Position;
                P2.Y:=P1.Y;
                Pt1:=Viewport.Project(P1);
                Pt2:=Viewport.Project(P2);
                Viewport.DrawingCanvas.MoveTo(Pt1.X,Pt1.Y);
                Viewport.DrawingCanvas.LineTo(Pt2.X,Pt2.Y);
                if Viewport.ViewType=fvBodyplan then Width:=0
                                                else Width:=Viewport.DrawingCanvas.TextWidth(Str);
                if Viewport.ViewType=fvBodyplan then
                begin
                   Viewport.DrawingCanvas.TextOut(Pt1.X,Pt1.Y,Str);
                   Viewport.DrawingCanvas.TextOut(Pt2.X-Width,Pt2.Y-Height,str);
                end else
                begin
                  Viewport.DrawingCanvas.TextOut(Pt1.X,Pt1.Y-Height,Str);
                  Viewport.DrawingCanvas.TextOut(Pt2.X-Width,Pt2.Y-Height,str);
                end;
                if (Visibility.ModelView=mvBoth) or (Viewport.ViewType=fvBodyplan) then
                begin
                  P1.Y:=-Position;
                  P2.Y:=P1.Y;
                  Str:=ConvertDimension(-Position,ProjectSettings.ProjectUnits);
                  Width:=Viewport.DrawingCanvas.TextWidth(Str);
                  Pt1:=Viewport.Project(P1);
                  Pt2:=Viewport.Project(P2);
                  Viewport.DrawingCanvas.MoveTo(Pt1.X,Pt1.Y);
                  Viewport.DrawingCanvas.LineTo(Pt2.X,Pt2.Y);
                  if Viewport.ViewType=fvBodyplan then
                  begin
                     Viewport.DrawingCanvas.TextOut(Pt1.X-Width,Pt1.Y,Str);
                     Viewport.DrawingCanvas.TextOut(Pt2.X-Width,Pt2.Y-Height,str);
                  end else
                  begin
                     Viewport.DrawingCanvas.TextOut(Pt2.X-Width,Pt2.Y,str);
                     Viewport.DrawingCanvas.TextOut(Pt1.X,Pt1.Y,Str);
                  end;
                end;
             end;
          end;
          if DrawWaterlines then
          begin
             P1:=Min;
             P2:=Max;
             for I:=1 to self.NumberofWaterlines do
             begin
                Position:=-Waterline[I-1].Plane.d;
                Str:=ConvertDimension(Position,ProjectSettings.ProjectUnits);
                P1.Z:=Position;
                P2.Z:=P1.Z;
                Pt1:=Viewport.Project(P1);
                Pt2:=Viewport.Project(P2);
                Viewport.DrawingCanvas.MoveTo(Pt1.X,Pt1.Y);
                Viewport.DrawingCanvas.LineTo(Pt2.X,Pt2.Y);
                Width:=Viewport.DrawingCanvas.TextWidth(Str);
                Viewport.DrawingCanvas.TextOut(Pt1.X,Pt1.Y-Height,Str);
                Viewport.DrawingCanvas.TextOut(Pt2.X-Width,Pt2.Y-Height,str);
             end;
          end;
       end;
    end;{DrawGrid}

begin
   if not Surface.Build then surface.Rebuild;
   // Draw intersectionlines BEFORE the surface is drawn,
   // so that the controlnet appears on top
   // But the intersections that should be drawn last depends on the view

   Surface.MainframeLocation:=Projectsettings.ProjectMainframeLocation;
   if Viewport.Viewtype<>fvPerspective then
   begin
      if Visibility.ShowGrid then
      begin
         // Draws a rectangular grid with measurements, bigger then the hull
         Drawgrid;
      end else
      begin
         // draws the actual splines as a dashed line
         if Viewport.ViewType<>fvBodyplan then if Visibility.ShowStations then for I:=1 to NumberOfStations do Station[I-1].Draw(Viewport);
         if Viewport.ViewType<>fvProfile then if Visibility.ShowButtocks then for I:=1 to NumberOfButtocks do Buttock[I-1].Draw(Viewport);
         if Viewport.ViewType<>fvPlan then if Visibility.ShowWaterlines then for I:=1 to NumberOfWaterlines do Waterline[I-1].Draw(Viewport);
         if Visibility.ShowDiagonals then for I:=1 to NumberOfDiagonals do Diagonal[I-1].Draw(Viewport);
      end;
      if (Viewport.ViewType=fvBodyplan) and (Visibility.ShowStations) then for I:=1 to NumberOfStations do Station[I-1].Draw(Viewport);
      if (Viewport.ViewType=fvProfile) and (Visibility.ShowButtocks) then for I:=1 to NumberOfButtocks do Buttock[I-1].Draw(Viewport);
      if (Viewport.ViewType=fvPlan) and (Visibility.ShowWaterlines) then for I:=1 to NumberOfWaterlines do Waterline[I-1].Draw(Viewport);
      if (Viewport.ViewType<>fvBodyplan) and (Visibility.ShowDiagonals) then for I:=1 to NumberOfDiagonals do Diagonal[I-1].Draw(Viewport);
   end else
   begin
      if Visibility.ShowStations then for I:=1 to NumberOfStations do Station[I-1].Draw(Viewport);
      if Visibility.ShowButtocks then for I:=1 to NumberOfButtocks do Buttock[I-1].Draw(Viewport);
      if Visibility.ShowWaterlines then for I:=1 to NumberOfWaterlines do Waterline[I-1].Draw(Viewport);
      if Visibility.ShowDiagonals then for I:=1 to NumberOfDiagonals do Diagonal[I-1].Draw(Viewport);
   end;
   if (Visibility.ShowMarkers) and (Viewport.ViewportMode=vmWireframe)then for I:=1 to NumberOfMarkers do Marker[I-1].Draw(Viewport);
   Surface.Color:=clDkGray;
   Surface.ShowControlNet:=Visibility.ShowControlNet;
   Surface.ShowInteriorEdges:=Visibility.ShowInteriorEdges;
   Surface.DrawMirror:=Visibility.ModelView=mvBoth;
   Surface.ShowNormals:=Visibility.ShowNormals;
   Surface.ControlPointSize:=Preferences.PointSize;
   Surface.CreaseColor:=Preferences.CreaseColor;
   Surface.CreaseEdgeColor:=Preferences.CreaseEdgeColor;
   Surface.EdgeColor:=Preferences.EdgeColor;
   Surface.CreasePointColor:=Preferences.CreasePointColor;
   Surface.RegularPointColor:=Preferences.RegularPointColor;
   Surface.CornerPointColor:=Preferences.CornerPointColor;
   Surface.DartPointColor:=Preferences.DartPointColor;
   Surface.Selectedcolor:=Preferences.SelectColor;
   Surface.LayerColor:=Preferences.LayerColor;
   Surface.NormalColor:=Preferences.NormalColor;
   Surface.LeakColor:=Preferences.LeakPointColor;
   Surface.CurvatureColor:=Preferences.CurvaturePlotColor;
   Surface.ShowCurvature:=Visibility.ShowCurvature;
   Surface.CurvatureScale:=Visibility.CurvatureScale;
   Surface.ShowControlCurves:=Visibility.ShowControlCurves;
   Surface.ControlCurveColor:=Preferences.ControlCurveColor;
   Surface.ZebraColor:=Preferences.ZebraStripeColor;
   if ProjectSettings.ProjectShadeUnderwaterShip then
   begin
      Plane.a:=0.0;
      Plane.b:=0.0;
      Plane.c:=1.0;
      Plane.d:=-(FindLowestHydrostaticsPoint+ProjectSettings.ProjectDraft);
      Surface.WaterlinePlane:=Plane;
      Surface.UnderWaterColor:=ProjectSettings.ProjectUnderWaterColor;
      Surface.ShadeUnderWater:=True;
   end else Surface.ShadeUnderWater:=False;
   Surface.Draw(Viewport);
   if (Viewport.Viewtype<>fvPerspective) and (Viewport.ViewportMode<>vmWireframe) and (Visibility.ShowGrid) then
   begin
      // Shaded viewport is a special case when visibility.drawgrid has been set to tru
      if Visibility.ShowStations then for I:=1 to NumberOfStations do Station[I-1].Draw(Viewport);
      if Visibility.ShowButtocks then for I:=1 to NumberOfButtocks do Buttock[I-1].Draw(Viewport);
      if Visibility.ShowWaterlines then for I:=1 to NumberOfWaterlines do Waterline[I-1].Draw(Viewport);
      if Visibility.ShowDiagonals then for I:=1 to NumberOfDiagonals do Diagonal[I-1].Draw(Viewport);
   end;
   if (Viewport.ViewportMode=vmWireframe) and (Visibility.ShowHydrostaticData) then
   begin
      // Draw hydrostatic data
      if FDesignHydrostatics.Draft<>ProjectSettings.ProjectDraft then FDesignHydrostatics.Draft:=ProjectSettings.ProjectDraft;

      if not FDesignHydrostatics.Calculated then FDesignHydrostatics.Calculate;
      if FDesignHydrostatics.Errors=[] then
      begin
         // Center of bouyancy
         if Visibility.FShowHydrostDisplacement then DrawPoint(FDesignHydrostatics.FData.CenterOfBuoyancy,'Displ='+FloatToStrF(FDesignHydrostatics.Data.Displacement,ffFixed,7,2),True);
         // Transverse metacentric height
         if Visibility.FShowHydrostMetacentricHeight then DrawPoint(Setpoint(FDesignHydrostatics.FData.CenterOfBuoyancy.X,0.0,FDesignHydrostatics.FData.KMtransverse),'KM='+FloatToStrF(FDesignHydrostatics.Data.KMtransverse,ffFixed,7,2),True);
         // Longitudinal center of floatation
         if Visibility.FShowHydrostLCF then DrawPoint(FDesignHydrostatics.FData.WaterplaneCOG,'LCF='+FloatToStrF(FDesignHydrostatics.Data.WaterplaneCOG.X,ffFixed,7,2),False);
         // Lateral center
         if Visibility.FShowHydrostLateralArea then DrawPoint(FDesignHydrostatics.FData.LateralCOG,Userstring(29)+'='+FloatToStrF(FDesignHydrostatics.Data.LateralArea,ffFixed,7,2),True);
         if (Viewport.ViewType=fvProfile) and (Visibility.FShowHydrostSectionalAreas) then
         begin
            // draw sectionalarea curve
            Curve:=TFreespline.Create;
            for I:=1 to length(FDesignHydrostatics.FData.SAC) do
            begin
               P.X:=FDesignHydrostatics.FData.SAC[I-1].X;
               P.Y:=0;
               if (FDesignHydrostatics.FData.BeamWaterline*FDesignHydrostatics.Draft)<>0 then P.Z:=2*(FDesignHydrostatics.FData.ModelMax.Z-FDesignHydrostatics.FData.ModelMin.Z)*FDesignHydrostatics.FData.SAC[I-1].Y/(FDesignHydrostatics.FData.BeamWaterline*FDesignHydrostatics.Draft)
                                                                                         else P.Z:=FDesignHydrostatics.FData.SAC[I-1].Y;
               P.Z:=P.Z+FDesignHydrostatics.FData.ModelMin.Z;
               Curve.Add(P);
            end;
            Curve.Color:=Preferences.HydrostaticsFontColor;
            Curve.Draw(Viewport);
            for I:=1 to Curve.NumberOfPoints do
            begin
               P:=Curve.Point[I-1];
               Pt:=Viewport.Project(P);
               Size:=round(Sqrt(Viewport.Zoom)*3);
               if Size<1 then Size:=1;
               Viewport.DrawingCanvas.MoveTo(Pt.X,Pt.Y-Size);
               Viewport.DrawingCanvas.LineTo(Pt.X,Pt.Y+Size);
               Viewport.DrawingCanvas.MoveTo(Pt.X-Size,Pt.Y);
               Viewport.DrawingCanvas.LineTo(Pt.X+Size,Pt.Y);
               Str:=FloatToStrF(FDesignHydrostatics.FData.SAC[I-1].Y,ffFixed,7,2);
               if P.X<FProjectsettings.ProjectMainframeLocation then Viewport.DrawingCanvas.TextOut(Pt.X-Viewport.DrawingCanvas.TextWidth(str),Pt.Y-Viewport.DrawingCanvas.TextHeight(str),Str)
                                                                else Viewport.DrawingCanvas.TextOut(Pt.X,Pt.Y-Viewport.DrawingCanvas.TextHeight(str),Str);
            end;
            Curve.Destroy;
         end;
      end;
   end;
   // Drawflowlines
   if Visibility.ShowFlowlines then For I:=1 to NumberOfFlowlines do Flowline[I-1].Draw(Viewport);

   if (Viewport.ViewportMode=vmShadeGauss) and (Surface.NumberOfControlFaces>0) and (Surface.MaxGaussCurvature-Surface.MinGaussCurvature>1e-7) then
   begin
      // Draw Legend with Gaussian curvature values
      NRect:=21;
      LegendHeight:=round(0.5*Viewport.ClientHeight);
      if LegendHeight<100 then LegendHeight:=100;
      if LegendHeight>0.9*Viewport.ClientHeight then LegendHeight:=round(0.9*Viewport.ClientHeight);
      if LegendHeight>250 then LegendHeight:=250;
      RectHeight:=round(LegendHeight/NRect);
      LegendHeight:=NRect*RectHeight;
      LegendWidth:=20;
      Viewport.PenColor:=Viewport.Color;
      Viewport.PenStyle:=psClear;
      Viewport.PenWidth:=1;
      Rect.Left:=5;
      Rect.Top:=5;
      Rect.Bottom:=Rect.Top+LegendHeight;
      Rect.Right:=Rect.Left+LegendWidth;
      Viewport.DrawingCanvas.Rectangle(Rect);
      Viewport.FontName:='Arial';
      Viewport.FontSize:=8;
      Viewport.FontColor:=Preferences.GridFontColor;
      NDecimal:=3;

      for I:=1 to NRect do
      begin
         Rect.Bottom:=Rect.Top+RectHeight;
         FillColor(I/Nrect,R,G,B);
         Viewport.BrushColor:=RGB(R,G,B);
         Viewport.BrushStyle:=bsSolid;
         Viewport.DrawingCanvas.Rectangle(Rect);
         Viewport.BrushStyle:=bsClear;
         if odd(I) then
         begin
            Tmp:=(I-1)/(NRect-1);
            if Tmp>=0.5 then
            begin
               Tmp:=2*(Tmp-0.5);
               Str:=FloatToStrF(Surface.MinGaussCurvature*Tmp,ffFixed,7,NDecimal);
            end else if Tmp<0.5 then
            begin
               Tmp:=2*(0.5-Tmp);
               Str:=FloatToStrF(Surface.MaxGaussCurvature*Tmp,ffFixed,7,NDecimal);
            end else Str:='0.0';
            Viewport.DrawingCanvas.TextOut(Rect.Right+5,(Rect.Top+Rect.Bottom-Viewport.DrawingCanvas.TextHeight(str)) div 2,Str);
         end;
         Rect.Top:=Rect.Top+RectHeight;
      end;
   end;
end;{TFreeShip.DrawToViewport}

procedure TFreeShip.Extents(Var Min,Max:T3DCoordinate);
// calculate the bounding box coordinates of the model
var I : integer;
begin
   if Surface.NumberOfControlFaces>0 then
   begin
      Surface.DrawMirror:=Visibility.ModelView=mvBoth;
      Min.X:=1e6;
      Min.Y:=Min.X;
      Min.Z:=Min.X;
      Max.X:=-Min.X;
      Max.Y:=-Min.Y;
      Max.Z:=-Min.Z;
      Surface.Extents(Min,Max);
      if Visibility.ShowMarkers then for I:=1 to NumberOfMarkers do Marker[I-1].Extents(Min,Max);
   end else
   begin
      if Surface.NumberOfControlPoints>1 then
      begin
         for I:=1 to Surface.NumberOfControlPoints do
         begin
            if I=1 then
            begin
               Min:=Surface.ControlPoint[I-1].Coordinate;
               Max:=Min;
            end else
            begin
               MinmAx(Surface.ControlPoint[I-1].Coordinate,Min,Max);
            end;
         end;
      end else
      begin
         Min.X:=-1;
         Min.Y:=Min.X;
         Min.Z:=Min.X;
         Max.X:=-Min.X;
         Max.Y:=Max.X;
         Max.Z:=Max.X;
      end;
   end;
end;{TFreeShip.Extents}

function TFreeShip.FindLowestHydrostaticsPoint:TFloatType;
var I,J     : Integer;
    First   : Boolean;
    Layer   : TFreeSubdivisionLayer;
begin
   Result:=Surface.Min.Z;
   First:=True;
   for I:=1 to NumberOfLayers do
   begin
      Layer:=Surface.Layer[I-1];
      if Layer.UseInHydrostatics then for J:=1 to Layer.Count do
      begin
         if First then
         begin
            Result:=Layer.Items[J-1].Min.Z;
            First:=False;
         end else
         begin
            if Layer.Items[J-1].Min.Z<Result then Result:=Layer.Items[J-1].Min.Z;
         end;
      end;
   end;
end;{TFreeShip.FindLowestHydrostaticsPoint}

// imports a number of longitudinally lines and creates developable surfaces between each two subsequent chines
procedure TFreeShip.ImportChines(Np:Integer;Chines:TFasterList);
var I,J        : integer;
    P,Min,Max  : T3DCoordinate;
    Pts,Pts2   : TFasterList;
    Tmp        : TFasterList;
    Points     : array of array of TFreeSubdivisionControlPoint;
    Point      : TFreeSubdivisionControlPoint;
    Edge       : TFreeSubdivisionControlEdge;
    Layer      : TFreeSubdivisionLayer;
    Spline     : TFreeSpline;
    Marker     : TFreeMarker;
    Matrix     : TFreeMatrix;
    Inv        : TFreeMatrix;
    OrgPts     : TFreeMatrix;
    NewPts     : TFreeMatrix;
    Curve      : TFreeSubdivisionControlCurve;
begin
   try
      for I:=1 to Chines.Count-1 do
      begin
         if I<=Surface.NumberOfLayers then Layer:=Surface.Layer[I-1]
                                      else Layer:=Surface.AddNewLayer;
         Layer.Name:=Userstring(186)+#32+IntToStr(I);
         Layer.Developable:=True;
      end;
      // add special layer to close the hull at centerline
      Layer:=Surface.AddNewLayer;
      Layer.Name:=Userstring(187);
      Setlength(Points,Np);

      // Prepare matrices
      Matrix:=TFreeMatrix.Create;
      Matrix.SetSize(Np,Np);
      Matrix.Fill(0.0);
      Matrix.Value[0,0]:=1.0;
      for I:=2 to Np-1 do
      begin
         Matrix.Value[I-1,I-2]:=1/6;
         Matrix.Value[I-1,I-1]:=2/3;
         Matrix.Value[I-1,I  ]:=1/6;
      end;
      Matrix.Value[Np-1,Np-1]:=1.0;
      // Invert matrix
      Inv:=Matrix.Invert;
      Matrix.Destroy;

      OrgPts:=TFreeMatrix.Create;
      OrgPts.SetSize(3,Np);

      for I:=1 to Np do Setlength(Points[I-1],Chines.Count);

      for I:=1 to Chines.Count do
      begin
         Spline:=Chines[I-1];
         OrgPts.Fill(0.0);
         for J:=1 to Np do
         begin
            P:=Spline.Value((J-1)/(Np-1));
            OrgPts.Value[J-1,0]:=P.X;
            OrgPts.Value[J-1,1]:=P.Y;
            OrgPts.Value[J-1,2]:=P.Z;
         end;
         // calculate new points
         NewPts:=Inv.Multiply(OrgPts);
         for J:=1 to Np do
         begin
            P.X:=NewPts.Value[J-1,0];
            P.Y:=NewPts.Value[J-1,1];
            if P.Y<0 then P.Y:=0;
            P.Z:=NewPts.Value[J-1,2];
            if (I=1) and (J=1) then
            begin
               Min:=P;
               Max:=Min;
            end else MinMax(P,Min,Max);
            Points[J-1][I-1]:=Surface.AddControlPoint(P);
         end;
         NewPts.Destroy;
      end;
      OrgPts.Destroy;
      // Delete inverted matrix
      Inv.Destroy;
      // Add chines as markers
      for I:=1 to Chines.Count do
      begin
         Spline:=Chines[I-1];
         Marker:=TFreeMarker.Create;
         Marker.FOwner:=self;
         Edit.Marker_Add(Marker);
         for J:=1 to Spline.NumberOfPoints do
         begin
            Marker.Add(Spline.Point[J-1]);
            Marker.Knuckle[J-1]:=Spline.Knuckle[J-1];
         end;
      end;
      // Setup controlfaces
      Pts:=TFasterlist.Create;
      for I:=2 to Np do
      begin
         for J:=2 to Chines.Count do
         begin
            Pts.Clear;
            Point:=Points[I-1][J-1];
            if Pts.IndexOf(Point)=-1 then Pts.Add(Point);
            Point:=Points[I-2][J-1];
            if Pts.IndexOf(Point)=-1 then Pts.Add(Point);
            Point:=Points[I-2][J-2];
            if Pts.IndexOf(Point)=-1 then Pts.Add(Point);
            Point:=Points[I-1][J-2];
            if Pts.IndexOf(Point)=-1 then Pts.Add(Point);
            if Pts.Count>2 then Surface.AddControlFace(Pts,True,Surface.Layer[J-2]);
         end;
      end;
   
      for I:=2 to Np do
      begin
         for J:=1 to Chines.Count do
         begin
            Edge:=Surface.EdgeExists(Points[I-2][J-1],Points[I-1][J-1]) as TFreeSubdivisionControlEdge;
            if Edge<>nil then Edge.Crease:=True;
         end;
      end;

      // Add controlcurves
      for J:=1 to Chines.Count do
      begin
         Curve:=TFreeSubdivisionControlCurve.Create(Surface);
         Surface.AddControlCurve(Curve);
         for I:=1 to Np do
         begin
            Curve.AddPoint(Points[I-1][J-1]);
            if I>1 then
            begin
               Edge:=Surface.EdgeExists(Points[I-2][J-1],Points[I-1][J-1]) as TFreeSubdivisionControlEdge;
               if Edge<>nil then Edge.Curve:=Curve;
            end;
         end;
      end;

      // Check for stem, keel and stern points to be closed
      Pts.Clear;
      // first stern
      for I:=Chines.Count downto 2 do Pts.Add(Points[Np-1][I-1]);
      // then keel
      for I:=Np downto 1 do Pts.Add(Points[I-1][0]);
      // and finally stem
      for I:=2 to Chines.Count do Pts.Add(Points[0][I-1]);
      Pts2:=TFasterList.Create;
      for I:=1 to Pts.Count do
      begin
         Point:=Pts[I-1];
         P:=Point.Coordinate;
         if P.Y<>0.0 then
         begin
            P.Y:=0;
            Point:=Surface.AddControlPoint(P);
            if Point.Coordinate.Y<>0.0 then
            begin
               Point.Coordinate:=P;
            end;
            Pts2.Add(Point);
         end else Pts2.Add(Point);
      end;
      Tmp:=TFasterList.Create;
      for I:=2 to Pts.Count do
      begin
         Tmp.Clear;
         if Tmp.IndexOf(Pts2[I-1])=-1 then Tmp.Add(Pts2[I-1]);
         if Tmp.IndexOf(Pts2[I-2])=-1 then Tmp.Add(Pts2[I-2]);
         if Tmp.IndexOf(Pts[I-2]) =-1 then Tmp.Add(Pts[I-2]);
         if Tmp.IndexOf(Pts[I-1]) =-1 then Tmp.Add(Pts[I-1]);
         if Tmp.Count>2 then Surface.AddControlFace(Tmp,False,Layer);
      end;

      // Now check if there are any edges on the bottom panel that are created by extruding the
      // bottom points and whose crease properties are set to true. This causes undesired knuckle in the bottompanel
      {
      for I:=Np-1 downto 2 do
      begin
         Point:=Points[I-1][0];
         if Point.Coordinate.Y>0 then
         begin
            for J:=1 to point.NumberOfEdges do
            begin
               Edge:=Point.Edge[J-1] as TFreeSubdivisionControlEdge;
               if ((Edge.Crease) and (Edge.StartPoint=Point) and (abs(Edge.EndPoint.Coordinate.Y)<1e-5)) or
                  ((Edge.Crease) and (Edge.EndPoint=Point) and (abs(Edge.StartPoint.Coordinate.Y)<1e-5)) then Edge.Crease:=False;
            end;
         end;
      end;
      }
      // set transom as knuckle
      for J:=2 to Chines.Count do
      begin
         Edge:=Surface.EdgeExists(Points[Np-1][J-2],Points[Np-1][J-1]) as TFreeSubdivisionControlEdge;
         if Edge<>nil then Edge.Crease:=true;
      end;
      // Delete unused layers;
      Edit.Layer_DeleteEmpty(True);
      // delete unused controlpoints
      for I:=Surface.NumberOfControlPoints downto 1 do if Surface.ControlPoint[I-1].NumberOfFaces=0 then Surface.ControlPoint[I-1].Delete;
      Tmp.Destroy;
      Pts2.Destroy;
      Pts.Destroy;
   finally
      Extents(Min,Max);
      //ProjectSettings.ProjectWaterDensity:=1.0;
      ProjectSettings.ProjectBeam:=2*Max.Y;
      ProjectSettings.ProjectLength:=Max.X-Min.X;
      ProjectSettings.ProjectDraft:=1.0;
      Build:=False;
      Precision:=fpHigh;
      Draw;
      FileChanged:=true;
      for I:=1 to Chines.Count do
      begin
         Spline:=Chines[I-1];
         Spline.Destroy;
      end;
   end;
end;{TFreeShip.ImportChines}

Procedure TFreeShip.LoadBinary(Source:TFreeFileBuffer);
var PrevCursor    : TCursor;
    I,N           : integer;
    Str           : String;
    Intersection  : TFreeIntersection;
    Marker        : TFreeMarker;
    Data          : TFreeBackgroundImageData;
    Flowline      : TFreeFlowline;
begin
   // Remember the filename because it will be erased by the clear method
   Str:=FFilename;
   Clear;
   FFilename:=Str;
   PrevCursor:=Screen.Cursor;
   Screen.Cursor:=crHourGlass;
   try
      Source.Reset;
      Source.Load(Str);
      if Str='FREE!ship' then
      begin
         Source.Load(FFileVersion);
         Source.Version:=FFileVersion;
         if (FFileVersion<=CurrentVersion) or (FFileVersion<=High(FFileVersion)) then
         begin
            Source.Load(I);
            FPrecision:=TFreePrecisionType(I);
            Visibility.LoadBinary(Source);
            ProjectSettings.LoadBinary(Source,nil);
            // Load actual subdivision-surface data.
            Surface.LoadBinary(Source);
            // Load stations
            Source.Load(N);
            FStations.Capacity:=N;
            for I:=1 to N do
            begin
               Intersection:=TFreeIntersection.Create(self);
               FStations.Add(Intersection);
               Intersection.LoadBinary(Source);
            end;
            // Load Buttocks
            Source.Load(N);
            FButtocks.Capacity:=N;
            for I:=1 to N do
            begin
               Intersection:=TFreeIntersection.Create(self);
               FButtocks.Add(Intersection);
               Intersection.LoadBinary(Source);
            end;
            // Load Waterlines
            Source.Load(N);
            FWaterlines.Capacity:=N;
            for I:=1 to N do
            begin
               Intersection:=TFreeIntersection.Create(self);
               FWaterlines.Add(Intersection);
               Intersection.LoadBinary(Source);
            end;
            if FileVersion>=fv180 then
            begin
               // Load Diagonals
               Source.Load(N);
               FDiagonals.Capacity:=N;
               for I:=1 to N do
               begin
                  Intersection:=TFreeIntersection.Create(self);
                  FDiagonals.Add(Intersection);
                  Intersection.LoadBinary(Source);
               end;
               if FileVersion>=fv191 then
               begin
                  // Load markers
                  Source.Load(N);
                  FMarkers.Capacity:=N;
                  for I:=1 to N do
                  begin
                     Marker:=TFreeMarker.Create;
                     Marker.FOwner:=Self;
                     Edit.Marker_Add(Marker);
                     Marker.LoadBinary(Source);
                  end;
                  if FileVersion>=fv210 then
                  begin
                     Source.Load(FResistanceDelftData,SizeOf(FResistanceDelftData));
                     Source.Load(FResistanceKaperData,SizeOf(TFreeKAPERResistanceData));
                     if FileVersion>=fv250 then
                     begin
                        Source.Load(N);
                        for I:=1 to N do
                        begin
                           Data:=TFreeBackgroundImageData.Create(self);
                           FBackgroundImages.Add(data);
                           Data.LoadBinary(Source);
                        end;
                        Source.Load(N);
                        FFlowlines.Capacity:=N;
                        for I:=1 to N do
                        begin
                           Flowline:=TFreeFlowline.Create(self);
                           FFlowlines.Add(Flowline);
                           Flowline.LoadBinary(Source);
                        end;
                     end;
                  end;
               end;
            end;
         end else MessageDlg(Userstring(113)+eol+
                             UserString(188)+'.',mtError,[mbOk],0);
      end else MessageDlg(Userstring(189),mtError,[mbOk],0);
      FileChanged:=False;
   finally
      Surface.DesiredSubdivisionLevel:=Ord(Precision)+1;
      Surface.Rebuild;
      Screen.Cursor:=PrevCursor;
      for I:=1 to NumberofBackgroundImages do BackgroundImage[I-1].UpdateViews;
      if Assigned(OnUpdateGeometryInfo) then OnUpdateGeometryInfo(self);
   end;
end;{TFreeShip.LoadBinary}

// loads the preview image from a file
procedure TFreeShip.LoadPreview(Filename:string;Image:TJPegImage);
var Source        : TFreeFileBuffer;
    I             : integer;
    Str           : String;
begin
   Source:=TFreeFileBuffer.Create;
   try
      Source.LoadFromFile(FileName);                // Load everything into memory
      Source.Reset;
      Source.Load(Str);
      if Str='FREE!ship' then
      begin
         Source.Load(FFileVersion);
         Source.Version:=FFileVersion;
         if FFileVersion>=fv210 then
         begin
            Source.Load(I);
            FPrecision:=TFreePrecisionType(I);
            Visibility.LoadBinary(Source);
            ProjectSettings.LoadBinary(Source,Image);
         end;
      end;
   finally
      Source.Destroy;
   end;
end;{TFreeShip.LoadPreview}

procedure TFreeShip.RebuildModel;
var PrevCursor : TCursor;
begin
   PrevCursor:=Screen.Cursor;
   if Screen.Cursor<>crHourglass then Screen.Cursor:=crHourglass;
   try
      Build:=False;
      Surface.DesiredSubdivisionLevel:=Ord(Precision)+1;
      Surface.Rebuild;
      Draw;
   finally
      if Screen.Cursor<>PrevCursor then Screen.Cursor:=PrevCursor;
   end;
end;{TFreeShip.RebuildModel}

procedure TFreeShip.Redraw;
var I : integer;
begin
   // Redraws model to all viewports using the current min/max coordinates of the boundingbox
   For I:=1 to NumberOfViewports do
   begin
      if Viewport[I-1].Zoom=1.0 then Viewport[I-1].ZoomExtents
                                else Viewport[I-1].Refresh;
   end;
   if LinesplanFrame<>nil then
   begin
      TFreeLinesplanframe(LinesplanFrame).Viewport.Refresh;
   end;
end;{TFreeShip.Redraw}

Procedure TFreeShip.SaveBinary(Destination:TFreeFileBuffer);
var PrevCursor : TCursor;
    I          : integer;
begin
   PrevCursor:=Screen.Cursor;
   Screen.Cursor:=crHourGlass;
   try
      Destination.Add('FREE!ship');
      Destination.Add(FileVersion);
      Destination.Add(Ord(Precision));
      Visibility.SaveBinary(Destination);
      ProjectSettings.SaveBinary(Destination);
      // Save actual subdivision-surface data.
      Surface.SaveBinary(Destination);
      // Save stations
      Destination.Add(NumberOfStations);
      For I:=1 to NumberOfStations do Station[I-1].SaveBinary(Destination);
      // Save Buttocks
      Destination.Add(NumberOfButtocks);
      For I:=1 to NumberOfButtocks do Buttock[I-1].SaveBinary(Destination);
      // Save Waterlines
      Destination.Add(NumberOfWaterlines);
      For I:=1 to NumberOfWaterlines do Waterline[I-1].SaveBinary(Destination);
      if FileVersion>=fv180 then
      begin
         // Save Diagonals
         Destination.Add(NumberOfDiagonals);
         For I:=1 to NumberOfDiagonals do Diagonal[I-1].SaveBinary(Destination);
         if FileVersion>=fv191 then
         begin
            // Save markers
            Destination.Add(NumberOfMarkers);
            for I:=1 to NumberOfMarkers do Marker[I-1].SaveBinary(Destination);
            if FileVersion>=fv210 then
            begin
               Destination.Add(FResistanceDelftData,SizeOf(FResistanceDelftData));
               Destination.Add(FResistanceKaperData,SizeOf(TFreeKAPERResistanceData));
               if FileVersion>=fv250 then
               begin
                  Destination.Add(NumberOfbackgroundImages);
                  for I:=1 to NumberOfBackgroundImages do BackgroundImage[I-1].SaveBinary(Destination);
                  Destination.Add(NumberOfFlowlines);
                  for I:=1 to NumberOfFlowlines do Flowline[I-1].SaveBinary(Destination);
               end;
            end;
         end;
      end;
   finally
      FileChanged:=False;
      Screen.Cursor:=PrevCursor;
   end;
end;{TFreeShip.SaveBinary}

procedure TFreeShip.SavePart(Faces:TFasterList);
var SaveDialog : TSaveDialog;
    Layers     : TFasterList;
    I,J,Index  : Integer;
    Edges      : TFasterList;
    Points     : TFasterList;
    Curves     : TFasterList;
    Face       : TFreeSubdivisionControlface;
    Edge       : TFreeSubdivisionControlEdge;
    P1,P2      : TFreeSubdivisionControlPoint;
    Curve      : TFreeSubdivisionControlCurve;
    Layer      : TFreeSubdivisionLayer;
    PartFile   : TFreeFileBuffer;
    PrevCursor : TCursor;
    Surface    : TFreeSubdivisionSurface;
    AddCurve   : Boolean;
begin
   Surface:=nil;
   if Faces.Count>0 then
   begin
      Face:=Faces[0];
      Surface:=Face.Owner;
   end;
   if Surface=nil then exit;


   SaveDialog:=TSaveDialog.Create(Owner);
   SaveDialog.InitialDir:=Preferences.ExportDirectory;
   SaveDialog.FileName:=ChangeFileExt(ExtractFilename(FileName),'.part');
   SaveDialog.Filter:='FREE!ship geometry part (*.Part)|*.part';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then
   begin
      Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
      // Extract controlPoints and control edges
      Layers:=TFasterList.Create;
      Points:=TFasterList.Create;
      Edges:=TFasterList.Create;
      Curves:=TFasterList.Create;
      for I:=1 to Faces.Count do
      begin
         Face:=Faces[I-1];
         if Layers.SortedIndexOf(Face.Layer)=-1 then Layers.AddSorted(Face.Layer);
         P1:=Face.Point[Face.NumberOfPoints-1] as TFreeSubdivisionControlPoint;
         for J:=1 to face.NumberOfpoints do
         begin
           P2:=Face.Point[J-1] as TFreeSubdivisionControlPoint;
           if Points.SortedIndexOf(P2)=-1 then Points.AddSorted(P2);
           Edge:=P1.Owner.EdgeExists(P1,P2) as TFreeSubdivisionControlEdge;
           if Edge<>nil then if Edges.SortedIndexOf(Edge)=-1 then Edges.AddSorted(Edge);
           P1:=P2;
         end;
      end;

      // process control curves
      for I:=1 to Surface.NumberOfControlCurves do
      begin
         Curve:=Surface.ControlCurve[I-1];
         // In order to export this curve, all associated controledges must be in the edges list
         AddCurve:=True and (Curve.NumberOfControlPoints>1);
         for J:=2 to Curve.NumberOfControlPoints do
         begin
            P1:=Curve.ControlPoint[J-2];
            P2:=Curve.ControlPoint[J-1];
            Edge:=Surface.EdgeExists(P1,P2) as TFreeSubdivisionControlEdge;
            if Edge<>nil then
            begin
               if Edges.SortedIndexOf(Edge)=-1 then AddCurve:=False;
            end else AddCurve:=False;
         end;
         if AddCurve then Curves.Add(Curve);
      end;

      Curves.Sort;
      Layers.Sort;

      PartFile:=TFreeFileBuffer.Create;
      PartFile.Version:=CurrentVersion;

      PrevCursor:=Screen.Cursor;
      Screen.Cursor:=crHourGlass;
      try
         Partfile.Add('FREE!ship partfile');
         Partfile.Add(ord(CurrentVersion));                                      // File version
         I:=Ord(ProjectSettings.ProjectUnits);
         Partfile.Add(I);                                                        // Write units type used (imperial or metric);
         Partfile.Add(Layers.Count);                                             // Number of layers in the file
         for I:=1 to Layers.Count do                                             // Save layer info
         begin
            Layer:=Layers[I-1];
            Layer.SaveBinary(Partfile);
         end;
         // Save controlpoints
         Partfile.Add(Points.Count);
         for I:=1 to Points.Count do
         begin
            P2:=Points[I-1];
            P2.SaveBinary(PartFile);
         end;
         // Save control edges
         Partfile.Add(Edges.Count);
         for I:=1 to Edges.Count do
         begin
            Edge:=Edges[I-1];
            Index:=Points.SortedIndexOf(Edge.StartPoint);
            Partfile.Add(Index);
            Index:=Points.SortedIndexOf(Edge.EndPoint);
            Partfile.Add(Index);
            Partfile.Add(Edge.Crease);
         end;
         // save controlfaces
         Partfile.Add(Faces.Count);
         for I:=1 to Faces.Count do
         begin
            Face:=Faces[I-1];
            Partfile.Add(Face.NumberOfpoints);
            for J:=1 to Face.NumberOfPoints do
            begin
               Index:=Points.SortedIndexOf(Face.Point[J-1]);
               Partfile.Add(Index);
            end;
            Index:=Layers.SortedIndexOf(Face.Layer);
            Partfile.Add(Index);
         end;
         // Save controlcurves
         Partfile.Add(Curves.Count);
         for I:=1 to Curves.Count do
         begin
            Curve:=Curves[I-1];
            Partfile.Add(Curve.NumberOfControlPoints);
            for J:=1 to Curve.NumberOfControlPoints do
            begin
               P2:=Curve.ControlPoint[j-1];
               Index:=points.SortedIndexOf(P2);
               Partfile.Add(Index);
            end;
         end;
         Partfile.SaveToFile(ChangeFileExt(SaveDialog.FileName,'.part'));
      finally
         Screen.Cursor:=PrevCursor;
      end;
      Partfile.Destroy;
      Points.Destroy;
      Edges.Destroy;
      Curves.Destroy;
      Layers.Destroy;
   end;
   SaveDialog.Destroy;
end;{TFreeShip.SavePart}

procedure TFreeShip.SubmergedHullExtents(Wlplane:T3DPlane;var Min,Max:T3DCoordinate);
var I,J,K,L    : Integer;
    FirstPoint : boolean;
    Layer      : TFreeSubdivisionLayer;
    Face       : TFreeSubdivisionControlFace;
    Child      : TFreeSubdivisionFace;
    P1,P2,P    : T3DCoordinate;
    s1,s2,T    : TFloatType;
begin
   FirstPoint:=True;
   for I:=1 to NumberOfLayers do
   begin
      Layer:=Surface.Layer[I-1];
      if Layer.UseInHydrostatics then for J:=1 to Layer.Count do
      begin
         Face:=Layer.Items[J-1];
         for K:=1 to Face.ChildCount do
         begin
            Child:=Face.Child[K-1];
            P1:=Child.Point[Child.NumberOfPoints-1].Coordinate;
            s1:=WlPlane.a*P1.x+WlPlane.b*P1.y+WlPlane.c*P1.z+WlPlane.d;
            for L:=1 to Child.NumberOfpoints do
            begin
               P2:=Child.Point[L-1].Coordinate;
               s2:=WlPlane.a*P2.x+WlPlane.b*P2.y+WlPlane.c*P2.z+WlPlane.d;


               if ((S1<0) and (S2>0)) or ((S1>0) and (S2<0)) then
               begin
                  // intersection
                  if S1=S2 then T:=0.5
                           else T:=-s1/(s2-s1);
                  P.X:=P1.X+T*(P2.X-P1.X);
                  P.Y:=P1.Y+T*(P2.Y-P1.Y);
                  P.Z:=P1.Z+T*(P2.Z-P1.Z);
                  if FirstPoint then
                  begin
                     Min:=P;
                     Max:=P;
                     FirstPoint:=False;
                  end else MinMax(P,Min,Max);
                  if Layer.Symmetric then
                  begin
                     P.Y:=-P.Y;
                     MinMax(P,Min,Max);
                  end;
               end;
               if S2<=0 then
               begin
                  if FirstPoint then
                  begin
                     Min:=P2;
                     Max:=P2;
                     FirstPoint:=False;
                  end else MinMax(P2,Min,Max);
                  if Layer.Symmetric then
                  begin
                     P2.Y:=-P2.Y;
                     MinMax(P2,Min,Max);
                  end;
               end;
               P1:=P2;
               S1:=S2;
            end;
         end;
      end;
   end;
   if FirstPoint then
   begin
      // no valid points found
      Min:=ZERO;
      Max.X:=1;
      Max.Y:=1;
      Max.Z:=1;
   end;
end;{TFreeShip.SubmergedHullExtents}

procedure TFreeShip.KeyUp(Viewport:TfreeViewport;var Key: Word;Shift: TShiftState);
const Left  = 37;
      Right = 39;
      Up    = 38;
      Down  = 40;
var Point      : TFreeSubdivisionControlPoint;
    P          : T3DCoordinate;
begin
   if (Key in [Left..Down]) and (Viewport.ViewType<>fvPerspective) and (ActiveControlPoint<>nil) then
   begin
      Edit.CreateUndoObject(Userstring(190),True);
      Point:=ActiveControlPoint;
      FileChanged:=True;
      Build:=False;
      P:=Point.Coordinate;
      Case Viewport.Viewtype of
         fvProfile      : Case Key of
                             Left  : P.X:=P.X-Visibility.CursorIncrement;
                             Up    : P.Z:=P.Z+Visibility.CursorIncrement;
                             Right : P.X:=P.X+Visibility.CursorIncrement;
                             Down  : P.Z:=P.Z-Visibility.CursorIncrement;
                          end;
         fvPlan         : Case Key of
                             Left  : P.X:=P.X-Visibility.CursorIncrement;
                             Up    : P.Y:=P.Y+Visibility.CursorIncrement;
                             Right : P.X:=P.X+Visibility.CursorIncrement;
                             Down  : P.Y:=P.Y-Visibility.CursorIncrement;
                          end;
         fvBodyplan     : Case Key of
                             Left  : if P.X<=self.ProjectSettings.ProjectMainframeLocation then P.Y:=P.Y+Visibility.CursorIncrement
                                                                                           else P.Y:=P.Y-Visibility.CursorIncrement;
                             Up    : P.Z:=P.Z+Visibility.CursorIncrement;
                             Right : if P.X<=self.ProjectSettings.ProjectMainframeLocation then P.Y:=P.Y-Visibility.CursorIncrement
                                                                                           else P.Y:=P.Y+Visibility.CursorIncrement;
                             Down  : P.Z:=P.Z-Visibility.CursorIncrement;
                          end;
      end;
      Point.Coordinate:=P;
      ActiveControlPoint:=Point;
      if ControlpointForm.Visible then
      begin
         // This lines updates the coordinate information in the controlpoint form
         ControlPointform.ActiveControlPoint:=Point;
         // and forces a repaint of the form
         if not Viewport.Focused then Viewport.SetFocus;
         application.ProcessMessages;
      end;
      Build:=False;
      Redraw;

   end else if (Key in [187,189,107,109]) and (Viewport.ViewType<>fvPerspective) then
   begin
      if Key in [107,187] then Visibility.CursorIncrement:=1.1*Visibility.CursorIncrement
                          else Visibility.CursorIncrement:=Visibility.CursorIncrement/1.1;
   end;
end;{TFreeShip.KeyUp}

procedure TFreeShip.MouseDown(Viewport:TFreeViewport;Button:TMouseButton;Shift:TShiftState;X,Y:integer;var ItemSelected:Boolean);
var I,J     : integer;
    Tmp     : integer;
    P3D     : T3DCoordinate;
    Point   : TFreeSubdivisionControlPoint;
    Edge    : TFreeSubdivisionControlEdge;
    Curve   : TFreeSubdivisionControlCurve;
    Face    : TFreeSubdivisionControlFace;
    Entity  : TFreeSubdivisionBase;
begin
   ItemSelected:=False;
   if Button=mbLeft then
   begin
      Case EditMode of
         emSelectItems      : begin
                                 Entity:=nil;
                                 // First check the vertices
                                 I:=1;
                                 while I<=Surface.NumberOfControlPoints do
                                 begin
                                    if Surface.ControlPoint[I-1].Visible then
                                    begin
                                       Point:=Surface.ControlPoint[I-1];
                                       Tmp:=Point.DistanceToCursor(X,Y,Viewport);
                                       if Tmp<=SelectDistance then
                                       begin
                                          Entity:=Point;
                                          //Point.Selected:=not Point.Selected;
                                          ItemSelected:=True;
                                          // Draw the selected point to all viewports
                                          for J:=1 to NumberOfViewports do if self.Viewport[J-1].ViewportMode=vmWireframe then Point.Draw(self.Viewport[J-1]);
                                          break;
                                       end;
                                    end;
                                    Inc(I);
                                 end;
                                 if Entity=nil then
                                 begin
                                    // No points found, search for nearest controlEdge
                                    I:=1;
                                    while I<=Surface.NumberOfControlEdges do
                                    begin
                                       if Surface.ControlEdge[I-1].Visible then
                                       begin
                                          Edge:=Surface.ControlEdge[I-1];
                                          Tmp:=Edge.DistanceToCursor(X,Y,P3D,Viewport);
                                          if Tmp<=SelectDistance then
                                          begin
                                             Entity:=Edge;
                                             Edge.Selected:=not Edge.Selected;
                                             // If CTRL key is pressed, select multiple edges in one pass
                                             // by tracing regular edges to a boundary or irregular points
                                             if (ssCtrl in shift) then
                                             begin
                                                Edge.Trace;
                                             end;
                                             ItemSelected:=True;
                                             // Draw the selected edge to all viewports
                                             for J:=1 to NumberOfViewports do Self.Viewport[J-1].Refresh;
                                             break;
                                          end;
                                       end;
                                       Inc(I);
                                    end;
                                 end;
                                 if (Entity=nil) and (Visibility.ShowInteriorEdges) then
                                 begin
                                    Surface.ShowInteriorEdges:=True;
                                    // No edges found, search for nearest control-face
                                    I:=1;
                                    while I<=Surface.NumberOfControlFaces do
                                    begin
                                       if Surface.ControlFace[I-1].Visible then
                                       begin
                                          Face:=Surface.ControlFace[I-1];
                                          Tmp:=Face.DistanceToCursor(X,Y,P3D,Viewport);
                                          if Tmp<=SelectDistance then
                                          begin
                                             Entity:=Face;
                                             Face.Selected:=not Face.Selected;
                                             // If CTRL key is pressed, select all connected controlfaces that
                                             // belong to the same layer and are not separated by a crease edge
                                             // and have the same selected state
                                             if (ssCtrl in shift) then
                                             begin
                                                Face.Trace;
                                             end;
                                             ItemSelected:=True;
                                             // Draw the selected faces to all viewports
                                             for J:=1 to NumberOfViewports do Self.Viewport[J-1].Refresh;
                                             break;
                                          end;
                                       end;
                                       Inc(I);
                                    end;
                                 end;
                                 if (Entity=nil) then
                                 begin
                                    I:=1;
                                    while I<=Surface.NumberOfControlCurves do
                                    begin
                                       if Surface.ControlCurve[I-1].Visible then
                                       begin
                                          Curve:=Surface.ControlCurve[I-1];
                                          Tmp:=Curve.DistanceToCursor(X,Y,Viewport);
                                          if Tmp<=SelectDistance then
                                          begin
                                             Entity:=Curve;
                                             Curve.Selected:=not Curve.Selected;
                                             ItemSelected:=True;
                                             // Draw the selected edge to all viewports
                                             for J:=1 to NumberOfViewports do if self.Viewport[J-1].ViewportMode=vmWireframe then Curve.Draw(self.Viewport[J-1]);
                                             break;
                                          end;
                                       end;
                                       Inc(I);
                                    end;
                                 end;

                                 // check flowlines
                                 if (Entity=nil) and (not ItemSelected) and (Visibility.ShowFlowlines) then
                                 begin
                                    I:=1;
                                    while I<=NumberOfFlowlines do
                                    begin
                                       Tmp:=Flowline[I-1].DistanceToCursor(X,Y,Viewport);
                                       if Tmp<=SelectDistance then
                                       begin
                                          Flowline[I-1].Selected:=not Flowline[I-1].Selected;
                                          ItemSelected:=True;
                                          // Draw the selected flowline to all viewports
                                          for J:=1 to NumberOfViewports do if self.Viewport[J-1].ViewportMode=vmWireframe then Flowline[I-1].Draw(self.Viewport[J-1]);
                                          break;
                                       end;
                                       Inc(I);
                                    end;
                                 end;

                                 // check Markers
                                 if (Entity=nil) and (not ItemSelected) and (Visibility.ShowMarkers) then
                                 begin
                                    I:=1;
                                    while I<=NumberOfMarkers do
                                    begin
                                       Tmp:=Marker[I-1].DistanceToCursor(X,Y,Viewport);
                                       if Tmp<=SelectDistance then
                                       begin
                                          Marker[I-1].Selected:=not Marker[I-1].Selected;
                                          ItemSelected:=True;
                                          // Draw the selected Marker to all viewports
                                          for J:=1 to NumberOfViewports do if self.Viewport[J-1].ViewportMode=vmWireframe then Marker[I-1].Draw(self.Viewport[J-1]);
                                          break;
                                       end;
                                       Inc(I);
                                    end;
                                 end;


                                 if Entity<>nil then // apparently SOMEthing has been selected
                                 begin
                                    if Entity is TFreeSubdivisionControlPoint then
                                    begin
                                       // If CTRL key is pressed, selection of multiple controlpoints is allowed,
                                       // otherwise select only ONE controlpoint
                                       Point:=Entity as TFreeSubdivisionControlPoint;
                                       if not (ssCtrl in shift) then
                                       begin
                                          if NumberOfSelectedControlPoints>0 then for I:=NumberOfSelectedControlPoints downto 1 do SelectedControlPoint[I-1].Selected:=False;
                                          Point.Selected:=True;
                                          for J:=1 to NumberOfViewports do self.Viewport[J-1].Refresh;
                                       end else
                                       begin
                                          Point.Selected:=not Point.Selected;
                                          if not Point.Selected then Point:=SelectedControlPoint[NumberOfSelectedControlPoints-1];
                                          for J:=1 to NumberOfViewports do self.Viewport[J-1].Refresh;
                                       end;
                                       if ActiveControlPoint<>point then ActiveControlPoint:=Point;
                                       FCurrentlyMoving:=True;
                                       FPointHasBeenMoved:=False;
                                       FPrevCursorPosition.X:=X;
                                       FPrevCursorPosition.Y:=Y;
                                    end else if Entity is TFreeSubdivisionControlCurve then
                                    begin
                                       for J:=1 to NumberOfViewports do if self.Viewport[J-1].ViewportMode=vmWireframe then self.Viewport[J-1].Refresh;
                                    end;
                                 end;
                              end;
      end;
   end else if Button=mbRight then
   begin
      EditMode:=emSelectItems;
   end;
   if not Viewport.Focused then Viewport.SetFocus;
end;{TFreeShip.MouseDown}

procedure TFreeShip.MouseMove(Viewport:TFreeViewport; Shift: TShiftState; X,Y: integer);
var P2D  : T2DCoordinate;
    P    : T3DCoordinate;
    Pt   : TPoint;
    Point: TFreeSubdivisionControlPoint;
    I    : Integer;
begin
   Case EditMode of
      emSelectItems      : if (ActiveControlPoint<>nil) and (FCurrentlyMoving) and (ssLeft in shift) and (Viewport.ViewType<>fvPerspective) then
                           begin
                              if (X<>FPrevCursorPosition.X) or (Y<>FPrevCursorPosition.Y) then
                              begin
                                 if FPointHasBeenMoved=False then
                                 begin
                                    // This is the first time the vertex is moved
                                    // Apply a certain threshold to make sure that
                                    // the controlpoint is not moved by accident
                                    if Sqrt(Sqr(X-FPrevCursorPosition.X)+Sqr(Y-FPrevCursorPosition.Y))<Threshold then exit;
                                    if ActiveControlPoint.Locked then
                                    begin
                                       MessageDlg(Userstring(191)+'!',mtWarning,[mbOk],0);
                                       exit;
                                    end;
                                    Edit.CreateUndoObject(Userstring(190),True);
                                 end;
                                 Point:=ActiveControlPoint;
                                 FileChanged:=True;
                                 Build:=False;
                                 FPointHasBeenMoved:=True;
                                 Pt.X:=X;
                                 Pt.Y:=Y;
                                 P2D:=Viewport.ProjectBackTo2D(Pt);
                                 P:=Point.Coordinate;
                                 Case Viewport.Viewtype of
                                    fvProfile      : begin
                                                        P.X:=P2D.X;
                                                        P.Z:=P2D.Y;
                                                     end;
                                    fvPlan         : begin
                                                        P.X:=P2D.X;
                                                        P.Y:=P2D.Y;
                                                     end;
                                    fvBodyplan     : begin
                                                        if P.X<=ProjectSettings.ProjectMainframeLocation then P.Y:=-P2D.X
                                                                                                         else P.Y:=P2D.X;
                                                        P.Z:=P2D.Y;
                                                     end;
                                 end;
                                 Point.Coordinate:=P;
                                 ActiveControlPoint:=Point;
                                 if ControlpointForm.Visible then
                                 begin
                                    // This lines updates the coordinate information in the controlpoint form
                                    ControlPointform.ActiveControlPoint:=Point;
                                    // and forces a repaint of the form
                                    if not Viewport.Focused then Viewport.SetFocus;
                                    application.ProcessMessages;
                                    TForm(Viewport.Owner).BringToFront;
                                 end;
                                 Build:=False;
                                 for I:=1 to NumberOfViewports do self.Viewport[I-1].Refresh;
                                 if LinesplanFrame<>nil then TFreeLinesplanframe(LinesplanFrame).Viewport.Refresh;
                                 FPrevCursorPosition.X:=X;
                                 FPrevCursorPosition.Y:=Y;
                              end;
                           end;
   end;
end;{TFreeShip.MouseMove}

procedure TFreeShip.MouseUp(Viewport:TFreeViewport;Shift:TShiftState;X,Y:integer);
begin
   FCurrentlyMoving:=False;
   if not Viewport.Focused then Viewport.SetFocus;
end;{TFreeShip.MouseUp}

procedure Register;
begin
  RegisterComponents('FreeShip', [TFreeShip]);
end;{Register}


end.
