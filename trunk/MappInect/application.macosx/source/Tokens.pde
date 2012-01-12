static public class Tokens
{
  
  //MAPPING
  public final static int NOTE = 0;
  public final static int CONTROLLER = 1;
  
  static final String[] midiTypesToken = {"note","controller"};
  //PROCESSOR
  
  static final int NONE = 0; //For multiple use
  
  static final int DIRECT = 0;
  static final int MAPPED= 1;
  static final int DISTANCE = 2;
  static final int ROTATION = 3;
  static final int BOOLEAN = 4;
  static final int CONDITIONNAL = 5;
  static final int FILTERED = 6;
  static final int ACTION = 7;
  static final int MULTI = 8;
  
  static final int LESS_THAN = 1;
  static final int GREATER_THAN = 2;
  static final int BETWEEN = 3;
  static final int LOWEST = 4;
  static final int GREATEST = 5;
  static final int AVERAGE = 6;
  static final int GATE = 7;
  static final int SUM = 8;
  static final int MINUS = 9;
  
  static final int AND = 0;
  static final int OR = 1;
  
  
  static final int ZERO = 1; //Also used in InactiveTokens.
  static final int CLIP = 2;
  static final int LOOP = 3;
  
  
  
  static final int TRIGGER = 1;
  static final int TOGGLE = 2;
  
  static final int CHANGE_SET = 1;
  static final int NEXT_SET = 2;
  static final int PREV_SET = 3;
  
  static final int KEEP_VALUE = 0;
  static final int STANDBY = 2;
  
  static final String[] processorTypesToken = {"direct","mapped","distance","rotation","boolean","conditionnal","filtered","action","multi"};
  static final String[] processorFiltersToken = {"none","less_than","greater_than","between","lowest","greatest","average","gate","sum","minus"};
  static final String[] processorOperatorsToken = {"and","or"};
  static final String[] processorOverflowsToken = {"none","zero","clip","loop"};
  static final String[] processorEffectsToken = {"none","trigger","toggle"}; 
  static final String[] processorActionsToken = {"none","changeSet","nextSet", "prevSet"};
  static final String[] processorInactiveToken = {"keepValue","zero","standby"};
  
  //ELEMENT
  
  static final int JOINT = 0;
  static final int POINT = 1;
  static final int VALUE = 2;
  
  static final int POSITION = 0;
  static final int VELOCITY = 1;
  static final int ACCELERATION=  2;
  
  static final int X = 0;
  static final int Y = 1;
  static final int Z = 2;
  static final int XY = 3;
  static final int XZ = 4;
  static final int YZ = 5;
  static final int VECTOR3D = 6;
  
  static final String[] mappingElementTypesToken = {"joint","point","value"};
  static final String[] propertiesToken = {"position","velocity","acceleration"};
  static final String[] axisToken = {"x","y","z","xy","xz","yz","3d"};
  
  
  // FEEDBACK
  static final int NO_FEEDBACK = -1;
  static final int CIRCLE_X = 0; //SAME AS X for direct mapping in MappingProcessor:getFeedbackMode();
  static final int CIRCLE_Y = 1; //SAME AS Y for direct mapping in MappingProcessor:getFeedbackMode();
  static final int CIRCLE_Z = 2; //SAME AS Z for direct mapping in MappingProcessor:getFeedbackMode();
  static final int CIRCLE_ROTATION = 3;
  static final int LINE_DISTANCE = 4;
  
  
  //MIDI OUTPUT
  public final static int SINGLE = 0;
  public final static int DOUBLE = 1;
  public final static int TRIPLE = 2;
  
  
  
  public static int getIndexForToken(String[] tokenArray, String token)
  {
    for (int i=0;i<tokenArray.length;i++)
    {
      if (tokenArray[i].equals(token)) {
        return i;
      }
    }
    
     println("### token "+token +" not found");
     return 0;
     
  }

}
