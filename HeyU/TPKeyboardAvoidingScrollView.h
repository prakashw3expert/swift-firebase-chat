
//Created By Puneet


#import <UIKit/UIKit.h>

@protocol TPKeyboardAvoidingScrollViewDelegate <UIScrollViewDelegate>

-(void)resignResponder;

@end

@interface TPKeyboardAvoidingScrollView : UIScrollView {
    CGRect priorFrame;
}

@property (assign, nonatomic) id <TPKeyboardAvoidingScrollViewDelegate,UIScrollViewDelegate>
delegate;



@end
